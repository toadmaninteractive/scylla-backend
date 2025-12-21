defmodule AyeSQLAuthorizedQueryRunner do

  use AyeSQL.Runner

  require Logger

  @impl true
  def run(%AyeSQL.Query{statement: stmt, arguments: args}, opts) do
if opts[:verbose], do: IO.inspect({:run, stmt, args, opts})
    {:ok, query!(stmt, args, opts)}
  end

  def query!(query, args, opts \\ []) do
    {claims, opts} = Keyword.pop(opts, :claims, %{})
    {default_claims, opts} = Keyword.pop(opts, :default_claims, %{})
    claims = default_claims |> Map.merge(claims)
    {use_role, opts} = Keyword.pop(opts, :use_role)
    {locale, opts} = Keyword.pop(opts, :locale)

    # workaround parameterizing do-block
    {query, args, claims} = case query do
      "do " <> _ -> {String.replace(query, "current_setting($1)", "current_setting('local.args')"), [], Map.put(claims, "local.args", Igor.Json.encode!(List.first(args)))}
      _ -> {query, args, claims}
    end

    init_cmd = []
    {init_cmd, claims} = case Map.pop(claims, :role) do
      {nil, claims} -> {init_cmd, claims}
      {role, claims} when use_role -> {[{"set role to #{role}", []} | init_cmd], claims}
      {_role, claims} -> {init_cmd, claims}
    end
    init_cmd = claims |> Enum.reduce(init_cmd, fn {k, v}, acc ->
      k = cond do
        is_binary(k) and String.contains?(k, ".") -> k
        true -> "jwt.claims.#{k}"
      end
      [{"select set_config($1, $2, true)", [k, to_string(v)]} | acc]
    end)
    init_cmd = case locale do
      nil -> init_cmd
      locale -> [{"select set_config('http.language', '#{locale}', true)", []} | init_cmd]
    end

    {repo, opts} = Keyword.pop(opts, :repo)
# if opts[:verbose], do: IO.inspect({:query, init_cmd, query, args, opts})

    # case Postgrex.transaction(repo, fn conn ->
    case repo.transaction(fn _ ->
      # try do
        # for {cmd, params} <- init_cmd, do: Postgrex.query!(conn, cmd, params)
        for {cmd, params} <- init_cmd, do: Ecto.Adapters.SQL.query!(repo, cmd, params)
        args = args |> Enum.map(fn
          nil -> nil
          v when is_boolean(v) -> v
          v when is_atom(v) -> Atom.to_string(v)
          v when is_struct(v, NaiveDateTime) ->  DateTime.from_naive!(v, "Etc/UTC")
          v -> v
        end)
        # %Postgrex.Result{columns: columns, rows: rows} = Postgrex.query!(conn, query, args)
        %Postgrex.Result{columns: columns, rows: rows} = Ecto.Adapters.SQL.query!(repo, query, args)
        # if opts[:verbose], do: IO.inspect({:raw, columns, rows})
        # if opts[:count] do
        #       case Ecto.Adapters.SQL.query(repo, "explain (format json) #{query}", args) do
        #         {:ok, %Postgrex.Result{rows: [[[%{"Plan" => %{"Plan Rows" => nrows}}]]]}} -> Util.Debug.inspect(nrows, :nrows)
        #         _ -> nil
        #       end
        # end
        # NB: there may be columns and/or rows nil!
        columns = columns || []
        columns = if opts[:into] === nil and opts[:atom_keys] !== false, do: Enum.map(columns, &String.to_atom/1), else: columns
        rows = (rows || [])
          |> Stream.map(&Stream.zip(columns, &1) |> Map.new())
        # if opts[:verbose], do: IO.inspect({:prepatched, rows |> Enum.map(& &1)})
        rows = if opts[:flatten], do: rows |> Stream.map(& &1 |> Map.values() |> List.first()), else: rows
        rows = if opts[:first], do: rows |> Enum.take(1) |> List.first(), else: rows
        # if opts[:verbose], do: IO.inspect({:patched, rows |> Enum.map(& &1)})
        rows = case opts[:into] do
          nil ->
            rows |> Enum.map(& &1)
          module when is_atom(module) ->
            rows |> Enum.map(&module.from_json!/1)
          fun when is_function(fun, 1) ->
            rows |> Enum.map(fun)
          fun when is_function(fun, 2) ->
            # status = case Postgrex.query(conn, "select current_setting('response.status', true)", []) do
            status = case Ecto.Adapters.SQL.query(repo, "select current_setting('response.status', true)", []) do
              {:ok, %Postgrex.Result{rows: [[status]]}} when is_binary(status) and status != "" -> String.to_integer(status)
              _ -> 200
            end
            # headers = case Postgrex.query(conn, "select current_setting('response.headers', true)", []) do
            headers = case Ecto.Adapters.SQL.query(repo, "select current_setting('response.headers', true)", []) do
              {:ok, %Postgrex.Result{rows: [[headers]]}} -> headers
              _ -> %{}
            end
            rows |> Enum.map(& fun.(&1, {status, headers}))
        end
        rows = if opts[:one] do
          case rows do
            [x] -> x
            _ -> raise DataProtocol.NotFoundError, is_binary(opts[:one]) && [message: opts[:one]] || []
          end
        else
          rows
        end
        rows
#       rescue
#         e in Postgrex.Error ->
#           case e do
#             %Postgrex.Error{postgres: %{code: :insufficient_privilege, message: message}} ->
#               raise DataProtocol.ForbiddenError, message: message
#             %Postgrex.Error{postgres: %{code: :insufficient_privilege}} ->
#               raise DataProtocol.ForbiddenError
#             %Postgrex.Error{postgres: %{code: :invalid_text_representation, detail: detail}} ->
#               raise DataProtocol.BadRequestError, error: :invalid_data, message: detail
#             %Postgrex.Error{postgres: %{code: :invalid_parameter_value, message: message}} ->
#               raise DataProtocol.BadRequestError, error: :invalid_data, message: message
#             # %Postgrex.Error{postgres: %{code: :no_data_found}} ->
#             #   raise DataProtocol.NotFoundError
#             # %Postgrex.Error{postgres: %{code: :not_null_violation, column: _column?}} ->
#             #   raise DataProtocol.NotFoundError
#             %Postgrex.Error{postgres: %{code: :check_violation, schema: schema, table: table, constraint: constraint}} ->
#               # error = get_obj_description(repo, "#{schema}.#{table}", constraint, "error")
# error = try do
#   get_obj_description(repo, "#{schema}.#{table}", constraint, "error")
# rescue
#   e ->
#     IO.inspect({:fok, e})
#     nil
# end
#               raise DataProtocol.BadRequestError, error: error || constraint
#             # %Postgrex.Error{postgres: %{code: :foreign_key_violation, constraint: constraint}} ->
#             #   raise DataProtocol.BadRequestError, error: String.to_atom(constraint)
#             %Postgrex.Error{postgres: %{code: :unique_violation, schema: schema, table: table, constraint: constraint}} ->
#               error = get_obj_description(repo, "#{schema}.#{table}", constraint, "error")
#               raise DataProtocol.BadRequestError, error: error || constraint
#             %Postgrex.Error{postgres: %{code: :in_failed_sql_transaction, message: message}} ->
#               raise DataProtocol.InternalServerError, message: message
#             %Postgrex.Error{postgres: %{pg_code: "PT400", message: message, hint: hint}} ->
#               raise DataProtocol.BadRequestError, error: String.to_atom(hint), message: message
#             %Postgrex.Error{postgres: %{pg_code: "PT403", message: message}} ->
#               raise DataProtocol.ForbiddenError, message: message
#             %Postgrex.Error{postgres: %{pg_code: "PT404", message: message}} ->
#               raise DataProtocol.NotFoundError, message: message
#             e ->
#               IO.inspect({:ex, e, query, args})
#               reraise e, __STACKTRACE__
#           end
#         e in DBConnection.EncodeError ->
#           case e do
#             %DBConnection.EncodeError{message: "Postgrex expected a binary of 16 or 36 bytes, got " <> _} ->
#               raise DataProtocol.BadRequestError, error: :invalid_data, message: "Malformed UUID"
#             e ->
#               IO.inspect({:ex, e, query, args})
#               reraise e, __STACKTRACE__
#           end
#       end
    end) do
      {:ok, result} ->
        # if opts[:verbose], do: IO.inspect({:result, result})
        result
#       {:error, %Postgrex.Error{postgres: %{code: :insufficient_privilege, message: message}}} ->
#         raise DataProtocol.ForbiddenError, message: message
#       {:error, %Postgrex.Error{postgres: %{code: :insufficient_privilege}}} ->
#         raise DataProtocol.ForbiddenError
#       {:error, %Postgrex.Error{postgres: %{code: :invalid_text_representation, detail: detail}}} ->
#         raise DataProtocol.BadRequestError, error: :invalid_data, message: detail
#       {:error, %Postgrex.Error{postgres: %{code: :invalid_parameter_value, message: message}}} ->
#         raise DataProtocol.BadRequestError, error: :invalid_data, message: message
#       # {:error, %Postgrex.Error{postgres: %{code: :no_data_found}}} ->
#       #   raise DataProtocol.NotFoundError
#       # {:error, %Postgrex.Error{postgres: %{code: :not_null_violation, column: _column?}}} ->
#       #   raise DataProtocol.NotFoundError
#       {:error, %Postgrex.Error{postgres: %{code: :check_violation, schema: schema, table: table, constraint: constraint}} = e} ->
#         # error = get_obj_description(repo, "#{schema}.#{table}", constraint, "error")
# error = try do
#   get_obj_description(repo, "#{schema}.#{table}", constraint, "error")
# rescue
#   e ->
#     IO.inspect({:fok, e})
#     nil
# end
#         raise DataProtocol.BadRequestError, error: error || constraint
#       # {:error, %Postgrex.Error{postgres: %{code: :foreign_key_violation, constraint: constraint}}} ->
#       #   raise DataProtocol.BadRequestError, error: String.to_atom(constraint)
#       {:error, %Postgrex.Error{postgres: %{code: :unique_violation, schema: schema, table: table, constraint: constraint}}} ->
#         error = get_obj_description(repo, "#{schema}.#{table}", constraint, "error")
#         raise DataProtocol.BadRequestError, error: error || constraint
#       {:error, %Postgrex.Error{postgres: %{code: :in_failed_sql_transaction, message: message}}} ->
#         raise DataProtocol.InternalServerError, message: message
#       {:error, %Postgrex.Error{postgres: %{pg_code: "PT400", message: message, hint: hint}}} ->
#         raise DataProtocol.BadRequestError, error: String.to_atom(hint), message: message
#       {:error, %Postgrex.Error{postgres: %{pg_code: "PT403", message: message}}} ->
#         raise DataProtocol.ForbiddenError, message: message
#       {:error, %Postgrex.Error{postgres: %{pg_code: "PT404", message: message}}} ->
#         raise DataProtocol.NotFoundError, message: message
#       {:error, error} ->
#         IO.inspect({:ex, error, query, args})
#         # reraise e, __STACKTRACE__
#         raise error
#       # e in DBConnection.EncodeError ->
#       #   case e do
#       #     %DBConnection.EncodeError{message: "Postgrex expected a binary of 16 or 36 bytes, got " <> _} ->
#       #       raise DataProtocol.BadRequestError, error: :invalid_data, message: "Malformed UUID"
#       #     e ->
#       #       IO.inspect({:ex, e, query, args})
#       #       reraise e, __STACKTRACE__
#       #   end
    end
  rescue
    e in Postgrex.Error ->
      {repo, _opts} = Keyword.pop(opts, :repo)
      case e do
        %Postgrex.Error{postgres: %{code: :insufficient_privilege, message: message}} ->
          raise DataProtocol.ForbiddenError, message: message
        %Postgrex.Error{postgres: %{code: :insufficient_privilege}} ->
          raise DataProtocol.ForbiddenError
        %Postgrex.Error{postgres: %{code: :invalid_text_representation, detail: detail}} ->
          raise DataProtocol.BadRequestError, error: :invalid_data, message: detail
        %Postgrex.Error{postgres: %{code: :invalid_parameter_value, message: message}} ->
          raise DataProtocol.BadRequestError, error: :invalid_data, message: message
        # %Postgrex.Error{postgres: %{code: :no_data_found}} ->
        #   raise DataProtocol.NotFoundError
        %Postgrex.Error{postgres: %{code: :not_null_violation, schema: schema, table: table, column: column}} ->
          case get_obj_description(repo, "#{schema}.#{table}", column, "error") do
            nil -> reraise e, __STACKTRACE__
            error -> raise DataProtocol.BadRequestError, error: String.to_atom(error)
          end
        %Postgrex.Error{postgres: %{code: :check_violation, schema: schema, table: table, constraint: constraint}} ->
          case get_obj_description(repo, "#{schema}.#{table}", constraint, "error") do
            nil -> reraise e, __STACKTRACE__
            error -> raise DataProtocol.BadRequestError, error: String.to_atom(error)
          end
        # %Postgrex.Error{postgres: %{code: :foreign_key_violation, constraint: constraint}} ->
        #   raise DataProtocol.BadRequestError, error: String.to_atom(constraint)
        %Postgrex.Error{postgres: %{code: :unique_violation, schema: schema, table: table, constraint: constraint}} ->
          case get_obj_description(repo, "#{schema}.#{table}", constraint, "error") do
            # nil -> reraise e, __STACKTRACE__
            nil ->
              cond do
                constraint == "#{table}_pkey" -> raise DataProtocol.BadRequestError, error: String.to_atom("#{table}_already_exists")
                String.starts_with?(constraint, "#{table}_") and String.ends_with?(constraint, "_key") ->
                  s = constraint |> String.replace_prefix("project_", "") |> String.replace_suffix("_key", "")
                  raise DataProtocol.BadRequestError, error: String.to_atom("#{s}_already_exists")
                true -> reraise e, __STACKTRACE__
              end
            # regexp_replace(constraint_name, '^(?:' || table_name || '_(\w+)_key|(' || table_name || ')_pkey)$', '\1\2_already_exists')
            error -> raise DataProtocol.BadRequestError, error: String.to_atom(error)
          end
        %Postgrex.Error{postgres: %{pg_code: "PT400", message: message, hint: hint}} ->
          raise DataProtocol.BadRequestError, error: String.to_atom(hint), message: message
        %Postgrex.Error{postgres: %{pg_code: "PT400", message: message}} ->
          raise DataProtocol.BadRequestError, error: String.to_atom(message)
        %Postgrex.Error{postgres: %{pg_code: "PT403", message: message}} ->
          raise DataProtocol.ForbiddenError, message: message
        %Postgrex.Error{postgres: %{pg_code: "PT404", message: message}} ->
          raise DataProtocol.NotFoundError, message: message
        %Postgrex.Error{postgres: %{pg_code: "PT409", message: message, hint: hint}} ->
          raise DataProtocol.ConflictError, error: String.to_atom(hint), message: message
        %Postgrex.Error{postgres: %{pg_code: "PT409", message: message}} ->
          raise DataProtocol.ConflictError, message: message
        %Postgrex.Error{postgres: %{pg_code: "PT500", message: message}} ->
          raise DataProtocol.InternalServerError, message: message
        %Postgrex.Error{postgres: %{pg_code: "P0001", message: message}} ->
          raise DataProtocol.InternalServerError, message: message
        e ->
          Logger.error("sql_err", data: %{exception: e, query: query, args: args}, domain: [:sql])
          reraise e, __STACKTRACE__
      end
    e in DBConnection.EncodeError ->
      case e do
        %DBConnection.EncodeError{message: "Postgrex expected a binary of 16 or 36 bytes, got " <> _} ->
          raise DataProtocol.BadRequestError, error: :invalid_data, message: "Malformed UUID"
        e ->
          Logger.error("sql_err", data: %{exception: e, query: query, args: args}, domain: [:sql])
          reraise e, __STACKTRACE__
      end
  end

  # defp get_obj_description(repo, table, object) do
  #   %Postgrex.Result{rows: [[description]]} = Ecto.Adapters.SQL.query!(
  #     repo,
  #     "select obj_description(oid) as description from pg_constraint where conrelid = $1::text::regclass and conname = $2",
  #     [table, object]
  #   )
  #   description
  # end

  defp get_obj_description(repo, table, object, key) do
    case Ecto.Adapters.SQL.query!(
      repo,
      """
      with parts as (select trim(unnest(string_to_array(obj_description(oid), '\\n'))) as kv from pg_constraint where conrelid = $1::text::regclass and conname = $2),
      kv as (select regexp_match(kv, '^@(\\w+)\\s+(.+?)\\s*') as kv from parts where kv != '')
      select kv[2] from kv where kv[1] = $3
      """,
      [table, object, key]
    ) do
      %Postgrex.Result{rows: [[description]]} -> description
      %Postgrex.Result{rows: []} -> nil
    end
  end

end

defmodule AyeSQLHelpers do

  defmacro definlinequeries(contents) do
    AyeSQL.Compiler.compile_queries(contents)
  end

  # defmacro defquery(contents, assigns \\ []) when is_binary(contents) and is_list(assigns) do
  #   contents
  #     |> EEx.eval_string(assigns: assigns)
  #     # |> AyeSQL.eval_query()
  # end

  # def bulk_insert(columns, rows) do
  #   Postgrex.transaction(:db_api, fn conn ->
  #     Postgrex.query!(conn, "set role to lotro_zeus", [])
  #     stream = Postgrex.stream(conn, "COPY api.coupon_code (#{Enum.join(columns, ", ")}) FROM STDIN", [])
  #     rows |> Enum.into(stream)
  #     # query = Postgrex.prepare!(conn, "", "COPY api.coupon_code FROM STDIN", [copy_data: true])
  #     # stream = Postgrex.stream(conn, query, [])
  #     # File.stream!("posts") |> Enum.into(stream)
  #   end)
  # end

  # def bulk_insert(columns, rows) do
  #   Repo.transaction(fn _ ->
  #     stream = Ecto.Adapters.SQL.stream(Repo, "COPY api.coupon_code (#{Enum.join(columns, ", ")}) FROM STDIN", [])
  #     rows |> Stream.map(& Enum.join(&1, "\t")) |> Enum.into(stream)
  #   end)
  # end

  def dynamic_update(repo, table, patch, id, opts) do
    query = patch
      |> Enum.with_index(fn {k, _v}, i -> "#{k} = $#{i+2}" end)
      |> Enum.join(", ")
      |> then(& "update #{table} set #{&1} where id = $1 returning *")
    args = patch
      |> Keyword.values()
      |> List.insert_at(0, id)
    AyeSQLAuthorizedQueryRunner.query!(query, args, [repo: repo] ++ opts)
  end

  def one!(result, error_message \\ nil) do
    case result do
      [x] -> x
      _ -> raise DataProtocol.NotFoundError, error_message && [message: error_message] || []
    end
  end

  # def one(result) do
  #   result |> List.first()
  # end

  def count!(result) do
    [%{count: count}] = result
    count
  end

end
