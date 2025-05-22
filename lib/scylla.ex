defmodule Scylla.ClickhouseInstanceId do

  defstruct [id: nil, code: nil]

  defguard is_clickhouse_instance_id(value) when is_struct(value, __MODULE__)

  def from_json!(x) when is_binary(x) do
    case Integer.parse(x) do
      :error -> %__MODULE__{code: x}
      {id, ""} -> %__MODULE__{id: id}
      {_, _} -> raise ArgumentError
    end
  end

end

defmodule Scylla.ProjectId do

  defstruct [id: nil, code: nil]

  defguard is_project_id(value) when is_struct(value, __MODULE__)

  def from_json!(x) when is_binary(x) do
    case Integer.parse(x) do
      :error -> %__MODULE__{code: x}
      {id, ""} -> %__MODULE__{id: id}
      {_, _} -> raise ArgumentError
    end
  end

end

defmodule Scylla do

  require Logger

  # ----------------------------------------------------------------------------

  # ----------------------------------------------------------------------------

  defmodule ClickhouseError do
    @enforce_keys [:message, :code]
    defexception [:message, :code, plug_status: 422]
  end

  # ----------------------------------------------------------------------------

  require Scylla.ClickhouseInstanceId
  require Scylla.ProjectId

  # ----------------------------------------------------------------------------

  import AyeSQLHelpers

  # ----------------------------------------------------------------------------

  def get_clickhouse_instance!(id) when is_integer(id), do: get_clickhouse_instance!(%Scylla.ClickhouseInstanceId{id: id})
  def get_clickhouse_instance!(id_or_code) when Scylla.ClickhouseInstanceId.is_clickhouse_instance_id(id_or_code) do
    Queries.get_clickhouse_instance!(id_or_code) |> one!()
  end

  # ----------------------------------------------------------------------------

  def create_clickhouse_instance!(%WebProtocol.CreateClickhouseInstanceRequest{} = data, opts \\ []) when is_list(opts) do
    Queries.create_clickhouse_instance!(%{data: data |> Map.from_struct()}) |> one!()
  end

  # ----------------------------------------------------------------------------

  def update_clickhouse_instance!(id_or_code, patch, opts \\ []) when Scylla.ClickhouseInstanceId.is_clickhouse_instance_id(id_or_code) and is_map(patch) and is_list(opts) do
    Queries.update_clickhouse_instance!(%{data: patch, where: id_or_code |> Map.from_struct()}) |> one!()
  end

  # ----------------------------------------------------------------------------

  def delete_clickhouse_instance!(id_or_code, opts \\ []) when Scylla.ClickhouseInstanceId.is_clickhouse_instance_id(id_or_code) and is_list(opts) do
    Queries.delete_clickhouse_instance!(%{where: id_or_code |> Map.from_struct()}) |> one!()
  end

  # ----------------------------------------------------------------------------

  def get_project!(id) when is_integer(id), do: get_project!(%Scylla.ProjectId{id: id})
  def get_project!(id_or_code) when Scylla.ProjectId.is_project_id(id_or_code) do
    Queries.get_project!(id_or_code) |> one!()
  end

  # ----------------------------------------------------------------------------

  def create_project!(%WebProtocol.CreateProjectRequest{clickhouse_instance_id: new_instance_id, clickhouse_db: new_db} = data, opts \\ []) when is_list(opts) do
    ensure_clickhouse_database!(nil, nil, new_instance_id, new_db, opts[:keep_db] !== true)
    Queries.create_project!(%{data: data |> Map.from_struct()}) |> one!()
  end

  # ----------------------------------------------------------------------------

  def update_project!(id_or_code, patch, opts \\ []) when Scylla.ProjectId.is_project_id(id_or_code) and is_map(patch) and is_list(opts) do
    %{clickhouse_instance_id: old_instance_id, clickhouse_db: old_db} = get_project!(id_or_code)
    new_instance_id = patch[:clickhouse_instance_id] || old_instance_id
    new_db = patch[:clickhouse_db] || old_db
    if new_instance_id !== old_instance_id or new_db !== old_db do
      ensure_clickhouse_database!(old_instance_id, old_db, new_instance_id, new_db, opts[:keep_db] !== true)
    end
    Queries.update_project!(%{data: patch, where: id_or_code |> Map.from_struct()}) |> one!()
  end

  # ----------------------------------------------------------------------------

  def delete_project!(id_or_code, opts \\ []) when Scylla.ProjectId.is_project_id(id_or_code) and is_list(opts) do
    %{clickhouse_instance_id: old_instance_id, clickhouse_db: old_db} = get_project!(id_or_code)
    ensure_clickhouse_database!(old_instance_id, old_db, nil, nil, opts[:keep_db] !== true)
    Queries.delete_project!(%{where: id_or_code |> Map.from_struct()}) |> one!()
  end

  # ----------------------------------------------------------------------------

  def regenerate_project_key!(id_or_code, key) when Scylla.ProjectId.is_project_id(id_or_code) do
    update_project!(id_or_code, %{
      key => Ecto.UUID.generate()
    })
  end

  # ----------------------------------------------------------------------------

  def fetch_project_events!(id_or_code, count) when Scylla.ProjectId.is_project_id(id_or_code) and is_integer(count) do
    %{clickhouse_instance_id: clickhouse_instance_id, clickhouse_db: database} = get_project!(id_or_code)
    clickhouse_instance = get_clickhouse_instance!(clickhouse_instance_id)
    table = Application.fetch_env!(:scylla, :clickhouse)[:table]
    call_clickhouse!(clickhouse_instance, "SELECT * FROM #{table} ORDER BY __inserted_at DESC LIMIT #{count} FORMAT JSON", database)
      |> Igor.Json.decode!()
      |> Map.fetch!("data")
      |> Stream.map(& &1 |> Map.drop(["__inserted_at"]))
      |> Enum.reverse()
  end

  # ----------------------------------------------------------------------------

  def get_ingestion_schema!(project_id_or_code, no_default \\ false)
  def get_ingestion_schema!(project_id_or_code, no_default) when Scylla.ProjectId.is_project_id(project_id_or_code), do: get_ingestion_schema!(get_project!(project_id_or_code), no_default)
  def get_ingestion_schema!(%{clickhouse_instance_id: clickhouse_instance_id, clickhouse_db: database}, no_default) when is_boolean(no_default) do
    clickhouse_instance = get_clickhouse_instance!(clickhouse_instance_id)
    table = Application.fetch_env!(:scylla, :clickhouse)[:table]
    sql = case no_default do
      true -> "SELECT name, trim(type || ' ' || default_kind) AS chdef, is_in_sorting_key as order_by FROM system.columns WHERE database = '#{database}' AND table = '#{table}' ORDER BY position FORMAT JSON"
      false -> "SELECT name, trim(type || ' ' || default_kind || ' ' || default_expression) AS chdef, is_in_sorting_key as order_by FROM system.columns WHERE database = '#{database}' AND table = '#{table}' ORDER BY position FORMAT JSON"
    end
    defs = call_clickhouse!(clickhouse_instance, sql, database)
      |> Igor.Json.decode!(keys: :atoms)
      |> Map.get(:data)
    fields = defs
      |> Enum.map(& {&1.name, &1.chdef})
    order_by = defs
      |> Enum.filter(& &1.order_by)
      |> Enum.map(& &1.name)
      |> Enum.join(", ")
    {fields, order_by}
  end

  def drop_backup_fields!(project_id_or_code, field_names) when Scylla.ProjectId.is_project_id(project_id_or_code), do: drop_backup_fields!(get_project!(project_id_or_code), field_names)
  def drop_backup_fields!(%{clickhouse_instance_id: clickhouse_instance_id, clickhouse_db: clickhouse_db} = project, field_names) when is_list(field_names) do
    clickhouse_instance = get_clickhouse_instance!(clickhouse_instance_id)
    table = Application.fetch_env!(:scylla, :clickhouse)[:table]
    sql = Scylla.get_ingestion_schema!(project)
      |> elem(0)
      |> Stream.filter(fn {name, _spec} -> String.contains?(name, "__backup_") and name in field_names end)
      |> Enum.map(fn {name, _spec} -> "DROP COLUMN #{name}" end)
      |> case do
        [] -> nil
        list -> "ALTER TABLE #{table} #{list |> Enum.join(", ")}"
      end
      |> Util.Debug.inspect(:mi)
    sql == nil or call_clickhouse!(clickhouse_instance, sql, clickhouse_db) == ""
  end

  def update_clickhouse_schema!(project_id_or_code, schema, opts \\ [])
  def update_clickhouse_schema!(project_id_or_code, schema, opts) when Scylla.ProjectId.is_project_id(project_id_or_code), do: update_clickhouse_schema!(get_project!(project_id_or_code), schema, opts)
  def update_clickhouse_schema!(%{id: project_id, code: project_code, clickhouse_instance_id: clickhouse_instance_id, clickhouse_db: database, preserve_db_columns: preserve_db_columns, backup_mode: backup_mode} = project, %IgorSchema.Schema{} = schema, opts) when is_list(opts) do
    clickhouse_instance = get_clickhouse_instance!(clickhouse_instance_id)
    %{custom_types: custom_types} = schema
    table = Application.fetch_env!(:scylla, :clickhouse)[:table]

    # options
    force? = opts[:force]

    # get current fields
    {old_fields, old_order_by, no_table} = case get_ingestion_schema!(project) do
      {[], ""} -> {[], "", true}
      {fields, order_by} -> {fields, order_by, false}
    end
    old_fields = old_fields |> Jason.OrderedObject.new()

    # collect new fields
    empty = [
      {"__inserted_at", %{meta: %{"clickhouse.type" => "DateTime64(3)"}, default: "now64()"}}
    ]
    {all_fields, variant_fields, _children_fields} = process_schema(empty, schema, project_code)
    relevant_fields = all_fields
    new_fields = relevant_fields
      |> Enum.map(fn {name, spec} -> {name, clickhouse_field_type(spec, custom_types)} end)
      |> Jason.OrderedObject.new()

# IO.inspect({:fi, old_fields, new_fields})
# raise "stop!"

    # collect new order_by expression
    new_order_by = relevant_fields
      |> Enum.reduce([], fn
        {name, %{meta: %{"clickhouse_order_by" => true}}}, acc -> [name | acc]
        {_, _}, acc -> acc
      end)
      |> Enum.reverse()
      |> Enum.join(", ")
    new_order_by = case new_order_by do
      "" -> "__inserted_at"
      _ -> new_order_by
    end

    # get migration index for backup fields
    # NB: format with leading zeros for better sorting order
    migration_index = Queries.get_project_schema_migration_count!(%{project_id: project.id}) |> count!()
    migration_index = "#{migration_index + 1}" |> String.pad_leading(3, "0")

    # calculate expected changes
    drop_fields = old_fields
      |> Enum.reject(fn {name, _spec} -> preserve_db_columns or String.contains?(name, "__backup_") end)
      |> Enum.filter(fn {name, _spec} -> new_fields[name] == nil end)
    modify_fields = new_fields
      |> Enum.filter(fn {name, spec} -> old_fields[name] != nil and old_fields[name] != spec end)
    add_fields = new_fields
      |> Enum.filter(fn {name, _spec} -> old_fields[name] == nil end)

# IO.inspect({:ops, migration_index, drop_fields, modify_fields, add_fields})

    # compose human-friendly schema diff
    clickhouse_schema_diff =
      [
        drop_fields |> Enum.map(fn {name, spec} -> {"#{name} :: #{spec}", "-"} end),
        modify_fields |> Enum.map(fn {name, spec} -> {"#{name} :: #{old_fields[name]} -> #{spec}", "*"} end),
        add_fields |> Enum.map(fn {name, spec} -> {"#{name} :: #{spec}", "+"} end)
      ]
      |> List.flatten()
      |> List.keysort(0, :asc)
      |> Enum.map(fn {diff, op} -> "#{op} #{diff}" end)
      |> Enum.join("\n")

# IO.inspect({:scdiff, migration_index, clickhouse_schema_diff})
# raise "stop"

    # collect expected migration commands
    drop_fields = drop_fields
      |> Enum.map(fn {name, _spec} -> "DROP COLUMN #{name}" end)
    modify_fields = modify_fields
      |> Enum.map(fn {name, spec} ->
        if backup_mode do
          [
            "DROP COLUMN IF EXISTS #{name}__backup__#{migration_index}",
            "RENAME COLUMN #{name} TO #{name}__backup__#{migration_index}",
            "ADD COLUMN #{name} #{spec}",
            # "INSERT INTO #{table} (#{name}) SELECT #{name}__backup__#{migration_index} FROM #{table}",
            cond do
              String.contains?(spec, "LowCardinality(") ->
                "INSERT INTO #{table} (#{name}) SELECT #{name}__backup__#{migration_index} FROM #{table}"
              String.contains?(spec, "Nullable(") or String.contains?(spec, " DEFAULT ") ->
                "INSERT INTO #{table} (#{name}) SELECT accurateCastOrNull(#{name}__backup__#{migration_index}, toColumnTypeName(#{name})) FROM #{table}"
              true ->
                "INSERT INTO #{table} (#{name}) SELECT accurateCastOrNull(#{name}__backup__#{migration_index}, toColumnTypeName(#{name})) ___casted___ FROM #{table} WHERE not isNull(___casted___)"
            end,
          ]
        else
          "MODIFY COLUMN #{name} #{spec}"
        end
      end)
      |> List.flatten()
    add_fields = add_fields
      |> Enum.map(fn {name, spec} -> "ADD COLUMN #{name} #{spec}" end)

    # separate alter table and data casting actions
    {copy_fields, modify_fields} = modify_fields
      |> Enum.split_with(& String.starts_with?(&1, "INSERT INTO #{table} "))

# IO.inspect({:ops, migration_index, drop_fields, modify_fields, add_fields, copy_fields})
# raise "stop"

    # form migration script
    migration = [drop_fields, modify_fields, add_fields]
      |> List.flatten()
      |> Enum.reject(fn x -> x == nil or String.trim(x) == "" end)
      |> Enum.join(", ")
    migration = cond do
      # empty -> do nothing
      migration == "" -> []
      # no such table -> create table
      no_table ->
        create_fields = new_fields
          |> Enum.map(fn {name, spec} -> "#{name} #{spec}" end)
          |> Enum.join(", ")
        [
          "CREATE TABLE IF NOT EXISTS #{table} (#{create_fields}) ENGINE = MergeTree() ORDER BY (#{new_order_by})",
        ]
      # table exists but order_by incompatible
      new_order_by !== old_order_by ->
        create_fields = new_fields
          |> Enum.map(fn {name, spec} -> "#{name} #{spec}" end)
          |> Enum.join(", ")
        select_fields = new_fields
          |> Enum.map(fn {name, _spec} -> name end)
          |> Enum.filter(& old_fields[&1] != nil)
          |> Enum.join(", ")
        actions = [
          # "CREATE TABLE __backup_#{table}_#{migration_index} (#{create_fields}) ENGINE = MergeTree() ORDER BY (#{new_order_by}) AS SELECT #{select_fields} FROM #{table}",
          "CREATE TABLE __backup_#{table}_#{migration_index} (#{create_fields}) ENGINE = MergeTree() ORDER BY (#{new_order_by})",
          "INSERT INTO __backup_#{table}_#{migration_index} (#{select_fields}) SELECT #{select_fields} FROM #{table}",
          "DROP TABLE #{table}",
          "RENAME TABLE __backup_#{table}_#{migration_index} TO #{table}",
        ] |> List.flatten()
        # require confirmation for dangerous actions
        if not force?, do: raise DataProtocol.ConflictError, error: :dangerous_action, details: actions
        actions
      # table exists -> alter table
      true ->
        actions = [
          "ALTER TABLE #{table} #{migration}",
          copy_fields,
        ] |> List.flatten()
        # require confirmation for dangerous actions
        # NB: do not raise if all DROP COLUMN followed with IF EXISTS (a backup action)
        if Regex.match?(~r'DROP COLUMN (?!IF EXISTS )', migration) and not force?, do: raise DataProtocol.ConflictError, message: "Potentially destructive action detected. See details. Set 'force' flag to proceed anyway.", error: :dangerous_action, details: actions
        actions
    end

IO.inspect({:mig, migration})
# raise "stop!"

    # raise DataProtocol.ConflictError, error: :dangerous_action, details: migration

    # perform migration
    _result = cond do
      # nothing to migrate? report ok
      migration == [] ->
        Logger.info("clickhouse: schema sustained for project code=#{project_code}", data: %{database: database}, domain: [:clickhouse])
        !no_table
      true ->
        steps = length(migration)
        for {sql, step} <- Enum.with_index(migration) do
          # try migration step
          try do
            call_clickhouse!(clickhouse_instance, sql, database) == ""
            Logger.info("clickhouse: schema update step #{step + 1}/#{steps} succeeded for project code=#{project_code}", data: %{database: database, sql: sql}, domain: [:clickhouse])
          rescue
            e in ClickhouseError ->
              cond do
                # do not stop on casting errors
                String.starts_with?(sql, "INSERT INTO ") ->
                  Logger.warn("clickhouse: schema update step #{step + 1}/#{steps} failed for project code=#{project_code}", data: %{database: database, sql: sql, exception: e}, domain: [:clickhouse])
                  false
                # stop on table alteration errors
                true ->
                  Logger.error("clickhouse: schema update step #{step + 1}/#{steps} failed for project code=#{project_code}", data: %{database: database, sql: sql, exception: e}, domain: [:clickhouse])
                  reraise e, __STACKTRACE__
              end
          end
        end |> Enum.all?(& &1 === true)
    end
    # unless result, do: raise DataProtocol.BadRequestError, error: :update_failed

    # store project new schema
    schema_json = schema
      |> Igor.Json.pack_value({:custom, IgorSchema.Schema})
      |> Igor.Json.encode!()
    update_project!(%Scylla.ProjectId{id: project_id}, %{schema: schema_json})

    # add migration history
    Queries.update_project_schema_migration!(%{where: %{project_id: project_id, schema: schema_json}, data: %{schema_diff: clickhouse_schema_diff}})

    # try to reoder clickhouse table columns
    {old_ordered_fields, _} = get_ingestion_schema!(project, true)
    {backup_fields, pinned_fields} = old_ordered_fields
      |> Enum.split_with(fn {name, _spec} -> String.contains?(name, "__backup_") end)
    {reordable_fields, pinned_fields} = pinned_fields
      |> Enum.split_with(fn {name, _spec} -> not List.keymember?(variant_fields, name, 0) end)
    pinned_fields = variant_fields
      |> Enum.map(fn {name, _} ->  List.keyfind!(pinned_fields, name, 0) end)
    reordable_fields = reordable_fields
      |> Enum.sort()
    backup_fields = backup_fields
      |> Enum.sort()
    new_ordered_fields = (pinned_fields ++ reordable_fields ++ backup_fields)
      |> Jason.OrderedObject.new()
    new_ordered_fields
      |> Enum.with_index()
      |> Enum.filter(fn {{name, _spec}, pos} -> Enum.at(old_ordered_fields, pos) |> elem(0) != name end)
      # |> Util.Debug.inspect(:sorted_chg)
      |> Enum.map(fn
        {{name, spec}, 0} -> "MODIFY COLUMN #{name} #{spec} FIRST"
        {{name, spec}, pos} -> "MODIFY COLUMN #{name} #{spec} AFTER #{Enum.at(new_ordered_fields, pos - 1) |> elem(0)}"
      end)
      |> case do
        [] -> :ok
        actions ->
IO.inspect({:reo, actions})
          reorder_sql = "ALTER TABLE #{table} #{actions |> Enum.join(", ")}"
          try do
            "" = call_clickhouse!(clickhouse_instance, reorder_sql, database)
            Logger.info("clickhouse: schema reorder succeeded for project code=#{project_code}", data: %{database: database, sql: reorder_sql}, domain: [:clickhouse])
          rescue
            e in ClickhouseError ->
              Logger.error("clickhouse: schema reorder failed for project code=#{project_code}", data: %{database: database, sql: reorder_sql, exception: e}, domain: [:clickhouse])
          end
      end

    # prepare schema parsers
    generate_event_parsers!(schema, project_code, database)
  end

  # ----------------------------------------------------------------------------

  defp sanitize(ev), do: ev |> Enum.reject(fn {_k, v} -> is_nil(v) end)
  defp escape(list) when is_list(list), do: Enum.map(list, &escape/1)
  defp escape("N" <> _ = x), do: "'#{x}'"
  defp escape("n" <> _ = x), do: "'#{x}'"
  defp escape(x), do: x

  def push_events!(%{code: project_code, clickhouse_instance_id: clickhouse_instance_id, clickhouse_db: database, event_validation: true}, events) when is_list(events) do
    Logger.metadata(project_code: project_code)
    %{valid: valid_events, invalid: invalid_events} = validate_against_schema(events, project_code, database)
    batches = valid_events
      |> Enum.map(fn {_vn, ev} -> sanitize(ev) end)
      |> Enum.group_by(& Keyword.keys(&1) |> Enum.join(","), & Keyword.values(&1) |> escape() |> Enum.join("\t"))
    clickhouse_instance = get_clickhouse_instance!(clickhouse_instance_id)
    table = Application.fetch_env!(:scylla, :clickhouse)[:table]
    for {columns, lines} <- batches do
      sql = "INSERT INTO #{table} (#{columns}) FORMAT TSVRaw"
      data = lines
        |> Enum.join("\n")
      Logger.debug("clickhouse: inserting #{length(lines)} events for project=#{project_code}", data: %{sql: sql, data: data}, domain: [:clickhouse])
      try do
        case call_clickhouse!(clickhouse_instance, data, database, sql) do
          "" ->
            Logger.info("clickhouse: inserted #{length(lines)} events for project=#{project_code}", data: %{}, domain: [:clickhouse])
            :ok
          message ->
            raise ClickhouseError, message: message, code: nil
            :ok
        end
      rescue
        e in ClickhouseError ->
          filename = "#{project_code}-#{Ecto.UUID.generate()}"
          if e.code == 0 or e.code in Util.config(:scylla, [:clickhouse, :transient_error_codes], []) do
            Logger.warn("clickhouse: transient error while inserting events for project=#{project_code}", data: %{exception: e}, domain: [:clickhouse])
            save_events_for_retry!(filename, clickhouse_instance_id, database, sql, data, e)
            Logger.info("clickhouse: saved parsed events to file new/#{filename} for later retry", data: %{filename: filename}, domain: [:clickhouse])
            :ok
          else
            Logger.error("clickhouse: permanent error while inserting events for project=#{project_code}", data: %{exception: e}, domain: [:clickhouse])
            save_events_for_analysis!(filename, clickhouse_instance_id, database, sql, data, e)
            Logger.info("clickhouse: saved parsed events to file err/#{filename} for manual analysis", data: %{filename: filename}, domain: [:clickhouse])
            :ok
          end
      end
    end
    # IO.inspect({:pe, valid_events, invalid_events})
    errors = invalid_events
      |> Enum.map(fn {errors, index, event} ->
        message = errors |> Enum.map(fn {name, message} -> "#{name} #{message}" end)
        Logger.error("schema: invalid event for project=#{project_code}: #{message}", data: %{event: event, errors: message}, domain: [:schema])
        errors |> Enum.map(fn {name, message} -> "events[#{index}].#{name} #{message}" end)
      end)
      |> List.flatten()
    # IO.inspect({:pe, errors})
    {length(valid_events), errors}
  end
  def push_events!(%{code: project_code, clickhouse_instance_id: clickhouse_instance_id, clickhouse_db: database, event_validation: false}, events) when is_list(events) do
    Logger.metadata(project_code: project_code)
    valid_events = events |> Enum.map(& {project_code, &1})
    batches = valid_events
      |> Enum.map(fn {_vn, ev} -> sanitize(ev) end)
      |> Enum.group_by(fn kv -> kv |> Enum.map(& elem(&1, 0)) |> Enum.join(",") end, fn kv -> kv |> Enum.map(& elem(&1, 1)) |> escape() |> Enum.join("\t") end)
    clickhouse_instance = get_clickhouse_instance!(clickhouse_instance_id)
    table = Application.fetch_env!(:scylla, :clickhouse)[:table]
    results = for {columns, lines} <- batches do
      sql = "INSERT INTO #{table} (#{columns}) FORMAT TSVRaw"
      data = lines
        |> Enum.join("\n")
      Logger.debug("clickhouse: inserting #{length(lines)} events for project=#{project_code}", data: %{sql: sql, data: data}, domain: [:clickhouse])
      try do
        case call_clickhouse!(clickhouse_instance, data, database, sql) do
          "" ->
            Logger.info("clickhouse: inserted #{length(lines)} events for project=#{project_code}", data: %{}, domain: [:clickhouse])
            :ok
          message ->
            raise ClickhouseError, message: message, code: nil
            :ok
        end
      rescue
        e in ClickhouseError ->
          filename = "#{project_code}-#{Ecto.UUID.generate()}"
          if e.code == 0 or e.code in Util.config(:scylla, [:clickhouse, :transient_error_codes], []) do
            Logger.warn("clickhouse: transient error while inserting events for project=#{project_code}", data: %{exception: e}, domain: [:clickhouse])
            save_events_for_retry!(filename, clickhouse_instance_id, database, sql, data, e)
            Logger.info("clickhouse: saved parsed events to file new/#{filename} for later retry", data: %{filename: filename}, domain: [:clickhouse])
            :ok
          else
            Logger.error("clickhouse: permanent error while inserting events for project=#{project_code}", data: %{exception: e}, domain: [:clickhouse])
            save_events_for_analysis!(filename, clickhouse_instance_id, database, sql, data, e)
            Logger.info("clickhouse: saved parsed events to file err/#{filename} for manual analysis", data: %{filename: filename}, domain: [:clickhouse])
            {e.message, data}
          end
      end
    end
    # IO.inspect({:pe, valid_events, invalid_events})
    errors = results
      |> Enum.reject(& &1 === :ok)
      |> Enum.map(fn {message, _data} ->
        # Logger.error("schema: invalid event for project=#{project_code}: #{message}", data: %{data: data, message: message}, domain: [:clickhouse])
        message
      end)
      |> List.flatten()
    # IO.inspect({:pe, errors})
    {length(valid_events), errors}
  end
  def push_events!(project_id_or_code, events) when Scylla.ProjectId.is_project_id(project_id_or_code), do: push_events!(get_project!(project_id_or_code), events)

  defp save_events_for_retry!(filename, clickhouse_instance_id, database, sql, data, _e) do
    save_dir = Util.config(:scylla, [:clickhouse, :save_events_directory], "tmp")
    File.mkdir_p!(Path.join([save_dir, "tmp"]))
    File.write!(Path.join([save_dir, "tmp", filename]), :zlib.gzip([to_string(clickhouse_instance_id), "\n", database, "\n", sql, "\n", data, "\n"]))
    File.mkdir_p!(Path.join([save_dir, "new"]))
    File.rename!(Path.join([save_dir, "tmp", filename]), Path.join([save_dir, "new", filename]))
  end

  defp save_events_for_analysis!(filename, clickhouse_instance_id, database, sql, data, _e) do
    save_dir = Util.config(:scylla, [:clickhouse, :save_events_directory], "tmp")
    File.mkdir_p!(Path.join([save_dir, "tmp"]))
    File.write!(Path.join([save_dir, "tmp", filename]), :zlib.gzip([to_string(clickhouse_instance_id), "\n", database, "\n", sql, "\n", data, "\n"]))
    File.mkdir_p!(Path.join([save_dir, "err"]))
    File.rename!(Path.join([save_dir, "tmp", filename]), Path.join([save_dir, "err", filename]))
  end

  def setup_saved_events() do
    save_dir = Util.config(:scylla, [:clickhouse, :save_events_directory], "tmp")
    File.mkdir_p!(Path.join([save_dir, "tmp"]))
    File.mkdir_p!(Path.join([save_dir, "new"]))
    File.mkdir_p!(Path.join([save_dir, "cur"]))
    for cur_filename <- Path.wildcard(Path.join([save_dir, "cur", "*"])) do
      filename = cur_filename |> Path.relative_to(Path.join([save_dir, "cur"]))
      new_filename = Path.join([save_dir, "new", filename])
      File.rename!(cur_filename, new_filename)
    end
  end

  def resend_saved_events() do
    save_dir = Util.config(:scylla, [:clickhouse, :save_events_directory], "tmp")
    for new_filename <- Path.wildcard(Path.join([save_dir, "new", "*"])) do
      filename = new_filename |> Path.relative_to(Path.join([save_dir, "new"]))
      cur_filename = Path.join([save_dir, "cur", filename])
      File.mkdir_p!(Path.join([save_dir, "cur"]))
      File.rename!(new_filename, cur_filename)
      case cur_filename |> File.read!() |> :zlib.gunzip() |> String.split("\n", parts: 4) do
        [clickhouse_instance_id, database, sql, data] ->
          try do
            case call_clickhouse!(String.to_integer(clickhouse_instance_id), data, database, sql) do
              "" ->
                Logger.warn("clickhouse: finally inserted saved parsed events from file new/#{filename}", data: %{filename: filename}, domain: [:clickhouse])
                File.rm!(cur_filename)
                {filename, :ok}
              message ->
                raise ClickhouseError, message: message, code: nil
            end
          rescue
            e in ClickhouseError ->
              if e.code == 0 or e.code in Util.config(:scylla, [:clickhouse, :transient_error_codes], []) do
                Logger.warn("clickhouse: transient error while inserting saved parsed events from file cur/#{filename}", data: %{filename: filename, exception: e}, domain: [:clickhouse])
                File.rename!(cur_filename, new_filename)
                Logger.info("clickhouse: put saved parsed events from file cur/#{filename} back to file new/#{filename} for later retry", data: %{filename: filename}, domain: [:clickhouse])
                {filename, :repeat}
              else
                Logger.error("clickhouse: permanent error while inserting saved parsed events from file cur/#{filename}", data: %{filename: filename, exception: e}, domain: [:clickhouse])
                File.mkdir_p!(Path.join([save_dir, "err"]))
                err_filename = Path.join([save_dir, "err", filename])
                File.rename!(cur_filename, err_filename)
                Logger.info("clickhouse: moved saved parsed events from file cur/#{filename} to file err/#{filename} for manual analysis", data: %{filename: filename}, domain: [:clickhouse])
                {filename, :error}
              end
          end
        _ ->
          File.rm!(cur_filename)
      end
    end
  end

  # ----------------------------------------------------------------------------

  defp ensure_clickhouse_database!(old_instance_id, old_db, new_instance_id, new_db, remove_old) do
    # TODO: may be optimize later
    old_instance = old_instance_id && get_clickhouse_instance!(old_instance_id)
    if remove_old and old_instance_id !== nil and old_db !== nil, do: "" = call_clickhouse!(old_instance, "DROP DATABASE IF EXISTS #{old_db}")
    new_instance = new_instance_id && get_clickhouse_instance!(new_instance_id)
    if remove_old and new_instance_id !== nil and new_db !== nil, do: "" = call_clickhouse!(new_instance, "DROP DATABASE IF EXISTS #{new_db}")
    if new_instance_id !== nil and new_db !== nil, do: "" = call_clickhouse!(new_instance, "CREATE DATABASE IF NOT EXISTS #{new_db}")
    # NB: we do not create "empty" table to save later ORDER BY problems
    # table = Application.fetch_env!(:scylla, :clickhouse)[:table]
    # "" = call_clickhouse!(new_instance, "CREATE TABLE IF NOT EXISTS #{table} (__inserted_at DateTime64(3) DEFAULT now64()) ENGINE = MergeTree() ORDER BY (__inserted_at)", new_db)
  end

  # ----------------------------------------------------------------------------

  defp call_clickhouse!(clickhouse_instance_id, data, database \\ nil, sql_query \\ nil)
  defp call_clickhouse!(clickhouse_instance_id, data, database, sql_query) when is_integer(clickhouse_instance_id) do
    call_clickhouse!(get_clickhouse_instance!(clickhouse_instance_id), data, database, sql_query)
  end
  defp call_clickhouse!(%{uri: uri, username: username, password: password}, data, database, sql_query) do
    require Logger
    Logger.debug("clickhouse: request #{inspect {uri, username, password, database, sql_query, data}}", domain: [:clickhouse])
    ClickhouseProtocol.ClickhouseApi.post_data(uri, data, username, password, database, sql_query)
  rescue
    e in Igor.Http.HttpError ->
      # IO.inspect({:us, e})
      message = "Clickhouse: " <> String.replace(e.body, ~r"(^.*DB::Exception: | \(version .*$)"s, "")
      code = e.headers |> Enum.reduce_while(nil, fn
        {"X-ClickHouse-Exception-Code", code}, _ -> {:halt, String.to_integer(code)}
        {_, _}, _ -> {:cont, nil}
      end)

      # DUPLICATE_COLUMN	15	1
      # NO_SUCH_COLUMN_IN_TABLE	16	1
      # NUMBER_OF_COLUMNS_DOESNT_MATCH	20	1
      # ATTEMPT_TO_READ_AFTER_EOF	32	13
      # BAD_ARGUMENTS	36	3
      # CANNOT_PARSE_DATETIME	41	108
      # ILLEGAL_TYPE_OF_ARGUMENT	43	9
      # UNKNOWN_FUNCTION	46	1
      # UNKNOWN_IDENTIFIER	47	9
      # UNKNOWN_TYPE	50	2
      # TABLE_ALREADY_EXISTS	57	1
      # UNKNOWN_TABLE	60	24
      # SYNTAX_ERROR	62	15
      # UNKNOWN_DATABASE	81	14
      # FILE_DOESNT_EXIST	107	16
      # UNKNOWN_USER	192	12
      # WRONG_PASSWORD	193	5
      # NETWORK_ERROR	210	25
      # CANNOT_GET_CREATE_TABLE_QUERY	390	16
      # NETLINK_ERROR	412	1
      # PATH_ACCESS_DENIED	481	2
      # AUTHENTICATION_FAILED	516	9

      reraise ClickhouseError, [message: message, code: code], __STACKTRACE__
    e in HTTPoison.Error ->
      case e do
        %{reason: :nxdomain} -> reraise ClickhouseError, [message: "Network: Clickhouse server not accessible", code: 0], __STACKTRACE__
        %{reason: :econnrefused} -> reraise ClickhouseError, [message: "Network: Clickhouse server not accessible", code: 0], __STACKTRACE__
        %{reason: :timeout} -> reraise ClickhouseError, [message: "Network: Clickhouse server not accessible", code: 0], __STACKTRACE__
        %{reason: :closed} -> reraise ClickhouseError, [message: "Network: Clickhouse server not accessible", code: 0], __STACKTRACE__
        %{reason: {:options, {:cb_info, {:gen_tcp, :tcp, :tcp_closed, :tcp_error, :tcp_passive}}}} -> reraise ClickhouseError, [message: "Network: Clickhouse server not accessible", code: 0], __STACKTRACE__
      end
  end

  # ----------------------------------------------------------------------------
  # ----------------------------------------------------------------------------
  # ----------------------------------------------------------------------------

  defp process_schema(acc, schema, project_code) do
    %{document_type: document_type, custom_types: custom_types} = schema
    %{fields: variant_fields, children: variant_children} = custom_types[document_type]
    children_fields = variant_children
      |> Map.values()
      |> Enum.map(& drill_fields([], custom_types, &1))
      |> List.flatten()
      |> Enum.drop(0)
      |> Enum.map(& &1 |> Map.get(:values))
      |> List.flatten()
      |> Enum.uniq()
      |> Enum.sort()
    all_fields = (variant_fields.values ++ children_fields)
      |> Enum.reduce(acc, fn {name, spec}, acc ->
          unless String.match?(name, ~r/^[a-z_][a-z0-9_]*$/i) do
            Logger.error("invalid_schema", data: %{project: project_code, args: [spec], exception: %{message: "invalid_name", info: name, hint: "alphanumeric"}}, domain: [:business])
            raise DataProtocol.BadRequestError, error: :invalid_name,
                message: "Field name '#{name}' must be alphanumeric",
                details: %{field: name}
          end
          if name === "__inserted_at" do
            Logger.error("invalid_schema", data: %{project: project_code, args: [spec], exception: %{message: "invalid_name", info: name, hint: "reserved"}}, domain: [:business])
            raise DataProtocol.BadRequestError, error: :invalid_name,
                message: "Field name '#{name}' is reserved. Please rename it",
                details: %{field: name}
          end
          case List.keyfind(acc, name, 0) do
            nil ->
              acc ++ [{name, spec}]
            {^name, ex_spec} ->
              if clickhouse_field_type(spec, custom_types) != clickhouse_field_type(ex_spec, custom_types) do
                if clickhouse_field_type(%{spec | optional: false, default: nil}, custom_types) != clickhouse_field_type(%{ex_spec | optional: false, default: nil}, custom_types) do
                  Logger.error("invalid_schema", data: %{project: project_code, args: [spec], exception: %{message: "invalid_name", info: name, hint: "clashing_type"}}, domain: [:business])
                  raise DataProtocol.BadRequestError, error: :clashing_type,
                    message: "Schema is invalid due to clashing types for field '#{name}'",
                    details: %{field: name, old: clickhouse_field_type(ex_spec, custom_types), new: clickhouse_field_type(spec, custom_types)}
                end
                List.keyreplace(acc, name, 0, {name, %{spec | optional: true}})
              else
                acc
              end
          end
        end)
    {all_fields, acc ++ variant_fields.values, children_fields}
  end

  # ----------------------------------------------------------------------------

  defp generate_event_parsers!(%IgorSchema.Schema{} = schema, project_code, database) when is_binary(project_code) and is_binary(database) do
    Logger.metadata(project_code: project_code)
    Logger.info("schema: generating parsers for project=#{project_code}", domain: [:schema])
    %{document_type: document_type, custom_types: types} = schema
    %{fields: variant_fields, children: variant_children, tag: tag_name} = types[document_type]
    module_source = [
"""
defmodule #{project_to_parser_module(project_code)} do
  import Ecto.Changeset
""",
    ]
    # generate base parser
    module_source = module_source ++ [generate_parser_module!({:entry, tag_name}, %{tag_name => variant_fields[tag_name]}, types)]
    # generate particular variant parsers
    module_source = module_source ++ (variant_children
      |> Enum.map(fn {variant_child_name, variant_child_type_name} ->
        variant_children_fields = drill_fields([], types, variant_child_type_name)
          |> List.flatten()
        fields = [variant_fields | variant_children_fields]
          |> List.flatten()
          |> Enum.reduce(%{}, fn fields, acc -> Map.merge(acc, fields |> Enum.into(%{})) end) # NB: Enum.into(%{}) due to fields may be an ordered object
        generate_parser_module!(variant_child_name, fields, types)
      end))
    module_source = module_source ++ [
"""
  defp require_presence(changeset, field_names) do
    valid_empty_field_names = changeset.changes
      |> Enum.filter(fn {_k, v} -> v === "" end)
      |> Keyword.keys()
    field_names = field_names -- valid_empty_field_names
    field_names |> Enum.reduce(changeset, fn field_name, changeset ->
      changeset |> validate_required(field_name, message: "missing_\#{field_name}", trim: false)
    end)
  end
end
"""
    ]
    module_source = module_source
      |> List.flatten()
      |> Enum.join("\n")
    # File.write!("./parser-#{project_code}.ex", module_source)
    [{_mod, _} | _] = Code.compile_string(module_source)
    Logger.info("schema: generated parsers for project=#{project_code}", domain: [:schema])
    :ok
  end
  defp generate_event_parsers!(schema, project_code, database) when is_map(schema) do
    %{schema: schema}
      |> Igor.Json.parse_field(:schema, {:custom, IgorSchema.Schema})
      |> case do
        {:ok, schema} -> schema
        {:error, error} -> raise DataProtocol.BadRequestError, message: "Project with code=#{project_code} has got invalid ingestion schema", error: :invalid_schema, details: Igor.ParseError.format_errors(error)
      end
      |> generate_event_parsers!(project_code, database)
  end
  defp generate_event_parsers!(schema, project_code, database) when is_binary(schema) do
    schema
      |> Igor.Json.decode!(objects: :ordered_objects) # NB: to correctly parse to ordered_maps
      |> generate_event_parsers!(project_code, database)
  end

  defp generate_parser_module!(variant_child_name, fields, types) do
    field_names = fields
      |> Enum.map(fn {k, _v} -> String.to_atom(k) end)
    default_struct = fields
      |> Enum.reduce(%{}, fn
        {name, %{default: default}}, acc -> Map.put_new(acc, String.to_existing_atom(name), default)
        _, acc -> acc
      end)
    required_field_names = fields
      |> Enum.reduce([], fn
        {name, %{default: nil, optional: false}}, acc -> [String.to_existing_atom(name) | acc]
        _, acc -> acc
      end)
    ecto_embedded_schema = fields
      |> Enum.reduce(%{}, fn {name, def}, acc ->
        {type, _validations} = ecto_field_type(def, types)
        Map.put_new(acc, String.to_existing_atom(name), type)
      end)
    ecto_validations = fields
      |> Enum.reduce([], fn {name, def}, acc ->
        {_type, validate_rules} = ecto_field_type(def, types)
        validations = validate_rules
          |> Enum.map(fn
            {:validate_number, [a | _] = _args} ->
              args = [{:message, "invalid_#{name}"} | a]
              "      |> validate_number(:#{name}, #{inspect(args)})"
            {:validate_inclusion, [a | _] = _args} ->
              "      |> validate_inclusion(:#{name}, #{inspect(a)}, message: \"invalid_#{name}\")"
            {:map, _, _, _} ->
              false
            unknown ->
              "      # unknown validation rule: #{inspect(unknown)}"
          end)
          |> Enum.filter(& &1)
        acc ++ validations
      end)
      |> List.flatten()
      |> Enum.join("\n")
    transformations = fields
      |> Enum.reduce([], fn {name, def}, acc ->
        {_type, transform_rules} = ecto_field_type(def, types)
        transformations = transform_rules
          |> Enum.map(fn
            {:map, mod, fun, _args} ->
              "            |> update_in([:#{name}], &#{mod}.#{fun}/1)"
            _ ->
              false
          end)
          |> Enum.filter(& &1)
        acc ++ transformations
      end)
      |> List.flatten()
      |> Enum.join("\n")
    case variant_child_name do
      {:entry, tag_name} ->
        """
  @spec from_json(json :: Map.t(), Keyword.t()) :: {:ok, Map.t()} | {:error, errors :: Keyword.t()}
  def from_json(json, opts \\\\ [])
  def from_json(json, opts) when is_map(json) do
    {#{inspect(default_struct)}, #{inspect(ecto_embedded_schema)}}
      |> cast(json, #{inspect(field_names)})
      |> require_presence(#{inspect(required_field_names)})
#{ecto_validations}
      |> apply_action(:update)
      |> case do
        {:ok, data} -> from_json(data.#{tag_name}, json, opts)
        {:error, %{errors: errors}} -> {:error, errors}
      end
      |> case do
        {:ok, data} ->
          {:ok, {data.#{tag_name}, data}}
        {:error, errors} ->
          errors = for {name, {_message, infos}} <- errors do
            case infos do
              [validation: :required] ->
                {name, "missing value"}
              [type: type, validation: :cast] ->
                {name, "must be \#{type}"}
              [validation: :number, kind: kind, number: number] ->
                {name, "must be \#{kind |> Atom.to_string() |> String.replace(\"_\", \" \")} \#{number}"}
              [validation: :inclusion, enum: enum] ->
                # {name, "must be one of [\#{inspect(Enum.join(enum, \", \"))}]"}
                {name, "must be one of [\#{enum |> Enum.join(\", \")}]"}
            end
          end
          {:error, errors}
      end
  end
  @spec from_json(json :: [Map.t()], Keyword.t()) :: %{valid: [Map.t()], invalid: [{errors :: Keyword.t(), index :: Integer.t(), json :: Map.t()}]}
  def from_json(json, opts) when is_list(json) do
    {valid, invalid} = json
      |> Enum.with_index()
      |> Enum.reduce({[], []}, fn {json, index}, {valid, invalid} ->
        case from_json(json, opts) do
          {:ok, data} -> {[data | valid], invalid}
          {:error, errors} -> {valid, [{errors, index, json} | invalid]}
        end
      end)
    %{valid: Enum.reverse(valid), invalid: Enum.reverse(invalid)}
  end
  def from_json(_json, _) do
    {:error, [event: "invalid format"]}
  end
"""
      variant_child_name ->
        """
  defp from_json("#{variant_child_name}", json, _opts) when is_map(json) do
    {#{inspect(default_struct)}, #{inspect(ecto_embedded_schema)}}
      |> cast(json, #{inspect(field_names)}, empty_values: [nil])
      |> require_presence(#{inspect(required_field_names)})
#{ecto_validations}
      |> apply_action(:update)
      |> case do
        {:ok, data} ->
          data = data
#{transformations}
          {:ok, data}
        {:error, %{errors: errors}} ->
          {:error, errors}
      end
  end
"""
    end
  end

  defp drill_fields(acc, types, type_name) do
    %{fields: fields} = spec = types[type_name]
    acc = [fields | acc]
    case spec do
      %{parent: parent_type_name} when is_binary(parent_type_name) ->
        drill_fields(acc, types, parent_type_name)
      _ -> acc
    end
  end

  # ----------------------------------------------------------------------------

  defp ecto_field_type(%IgorSchema.StringDescriptor{}, _types), do: {:string, []}
  defp ecto_field_type(%IgorSchema.KeyDescriptor{}, _types), do: {:string, []}
  defp ecto_field_type(%IgorSchema.BoolDescriptor{}, _types), do: {:boolean, [{:map, Scylla.Util, :boolean_to_byte, []}]}
  defp ecto_field_type(%IgorSchema.IntDescriptor{meta: %{"clickhouse.type" => "DateTime", "timestamp_mode" => timestamp_mode} = meta} = def, types) do
    {type, validations} = ecto_field_type(%{def | meta: Map.delete(meta, "clickhouse.type")}, types)
    case timestamp_mode do
      "s" -> {type, validations}
      "ms" -> {type, validations ++ [{:map, Scylla.Util, :milliseconds_to_seconds, []}]}
    end
  end
  defp ecto_field_type(%IgorSchema.IntDescriptor{meta: %{"clickhouse.type" => "DateTime64(3)", "timestamp_mode" => timestamp_mode} = meta} = def, types) do
    {type, validations} = ecto_field_type(%{def | meta: Map.delete(meta, "clickhouse.type")}, types)
    case timestamp_mode do
      "s" -> {type, validations ++ [{:map, Scylla.Util, :seconds_to_milliseconds, []}]}
      "ms" -> {type, validations}
    end
  end
  defp ecto_field_type(%{meta: %{"clickhouse.type" => _type}}, _types), do: {:string, []}
  defp ecto_field_type(%IgorSchema.IntDescriptor{type: :int8}, _types), do: {:integer, [{:validate_number, [[greater_than_or_equal_to: -128, less_than_or_equal_to: 127]]}]}
  defp ecto_field_type(%IgorSchema.IntDescriptor{type: :uint8}, _types), do: {:integer, [{:validate_number, [[greater_than_or_equal_to: 0, less_than_or_equal_to: 255]]}]}
  defp ecto_field_type(%IgorSchema.IntDescriptor{type: :int16}, _types), do: {:integer, [{:validate_number, [[greater_than_or_equal_to: -32768, less_than_or_equal_to: 32767]]}]}
  defp ecto_field_type(%IgorSchema.IntDescriptor{type: :uint16}, _types), do: {:integer, [{:validate_number, [[greater_than_or_equal_to: 0, less_than_or_equal_to: 65535]]}]}
  defp ecto_field_type(%IgorSchema.IntDescriptor{type: :int32}, _types), do: {:integer, [{:validate_number, [[greater_than_or_equal_to: -2147483648, less_than_or_equal_to: 2147483647]]}]}
  defp ecto_field_type(%IgorSchema.IntDescriptor{type: :uint32}, _types), do: {:integer, [{:validate_number, [[greater_than_or_equal_to: 0, less_than_or_equal_to: 4294967295]]}]}
  defp ecto_field_type(%IgorSchema.IntDescriptor{type: :int64}, _types), do: {:integer, [{:validate_number, [[greater_than_or_equal_to: -9223372036854775808, less_than_or_equal_to: 9223372036854775807]]}]}
  defp ecto_field_type(%IgorSchema.IntDescriptor{type: :uint64}, _types), do: {:integer, [{:validate_number, [[greater_than_or_equal_to: 0, less_than_or_equal_to: 18446744073709551615]]}]}
  defp ecto_field_type(%IgorSchema.FloatDescriptor{type: :float32}, _types), do: {:float, []}
  defp ecto_field_type(%IgorSchema.FloatDescriptor{type: :float64}, _types), do: {:float, []}
  defp ecto_field_type(%IgorSchema.EnumDescriptor{name: enum_type_name}, types), do: {:string, [{:validate_inclusion, [types[enum_type_name].values]}]}

  # ----------------------------------------------------------------------------

  defp project_to_parser_module(project_code) when is_binary(project_code) do
    "Scylla.Parsers.#{String.capitalize(project_code)}"
  end

  # ----------------------------------------------------------------------------

  def precompile_parsers() do
    for %{code: project_code, clickhouse_db: database, schema: schema} <- Queries.get_projects!(%{}) do
      if schema != nil and schema != "{}" do
        :ok = generate_event_parsers!(schema, project_code, database)
      end
    end
  end

  # ----------------------------------------------------------------------------

  defp validate_against_schema(events, project_code, database) when is_list(events) and is_binary(project_code) and is_binary(database) do
    parser_module_name = "Elixir." <> project_to_parser_module(project_code)
    parser_module = String.to_atom(parser_module_name)
    unless function_exported?(parser_module, :from_json, 2), do: raise DataProtocol.BadRequestError, error: :invalid_schema
    # TODO: customize parser here
    parser_options = []
    apply(parser_module, :from_json, [events, parser_options])
  end

  # ----------------------------------------------------------------------------

  defp clickhouse_field_type(%IgorSchema.EnumDescriptor{optional: true, default: nil} = def, _types) do
    raise DataProtocol.BadRequestError, error: :invalid_type_definition, details: "optional enum with no default is not supported: #{inspect(def)}"
  end
  defp clickhouse_field_type(%{default: default} = def, types) when not is_nil(default) do
    type = clickhouse_field_type(Map.delete(def, :default), types)
    cond do
      default == "now()" or default == "now64()" -> "#{type} DEFAULT #{default}"
      is_binary(default) -> "#{type} DEFAULT '#{default}'"
      is_float(default) and round(default) == default -> "#{type} DEFAULT #{round(default)}."
      is_boolean(default) -> "#{type} DEFAULT #{default && 1 || 0}"
      true -> "#{type} DEFAULT #{default}"
    end
  end
  defp clickhouse_field_type(%IgorSchema.StringDescriptor{low_cardinality: true} = def, types) do
    type = clickhouse_field_type(%{def | low_cardinality: false}, types)
    "LowCardinality(#{type})"
  end
  defp clickhouse_field_type(%{optional: true} = def, types) do
    type = clickhouse_field_type(%{def | optional: false}, types)
    "Nullable(#{type})"
  end
  defp clickhouse_field_type(%{meta: %{"clickhouse.type" => type}}, _types), do: type
  defp clickhouse_field_type(%IgorSchema.BoolDescriptor{}, _types), do: "UInt8"
  defp clickhouse_field_type(%IgorSchema.IntDescriptor{type: :int8}, _types), do: "Int8"
  defp clickhouse_field_type(%IgorSchema.IntDescriptor{type: :uint8}, _types), do: "UInt8"
  defp clickhouse_field_type(%IgorSchema.IntDescriptor{type: :int16}, _types), do: "Int16"
  defp clickhouse_field_type(%IgorSchema.IntDescriptor{type: :uint16}, _types), do: "UInt16"
  defp clickhouse_field_type(%IgorSchema.IntDescriptor{type: :int32}, _types), do: "Int32"
  defp clickhouse_field_type(%IgorSchema.IntDescriptor{type: :uint32}, _types), do: "UInt32"
  defp clickhouse_field_type(%IgorSchema.IntDescriptor{type: :int64}, _types), do: "Int64"
  defp clickhouse_field_type(%IgorSchema.IntDescriptor{type: :uint64}, _types), do: "UInt64"
  defp clickhouse_field_type(%IgorSchema.FloatDescriptor{type: :float32}, _types), do: "Float32"
  defp clickhouse_field_type(%IgorSchema.FloatDescriptor{type: :float64}, _types), do: "Float64"
  defp clickhouse_field_type(%IgorSchema.StringDescriptor{}, _types), do: "String"
  defp clickhouse_field_type(%IgorSchema.KeyDescriptor{}, _types), do: "String"
  defp clickhouse_field_type(%IgorSchema.EnumDescriptor{}, _types), do: "LowCardinality(String)"
  defp clickhouse_field_type(%{type: type}, _types), do: raise DataProtocol.BadRequestError, error: :unknown_type, info: type
  defp clickhouse_field_type(unknown, _types), do: raise DataProtocol.BadRequestError, error: :invalid_type_definition, details: inspect(unknown)

  # ----------------------------------------------------------------------------
  # ----------------------------------------------------------------------------
  # ----------------------------------------------------------------------------

  # ----------------------------------------------------------------------------

  defmodule Util do

    def seconds_to_milliseconds(x) when is_integer(x), do: x * 1000

    def milliseconds_to_seconds(x) when is_integer(x), do: div(x, 1000)

    def boolean_to_byte(nil), do: nil
    def boolean_to_byte(x) when is_boolean(x), do: x && 1 || 0

  end

  # ----------------------------------------------------------------------------

end
