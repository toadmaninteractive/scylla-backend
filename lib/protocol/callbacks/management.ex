defmodule WebProtocol.ScyllaManagementService.Impl do

  require Scylla.ClickhouseInstanceId
  require Scylla.ProjectId
  require WebProtocol.SchemaMigrationOrderBy
  require DataProtocol.OrderDirection
  require WebProtocol.BackupFieldOrderBy

  @moduledoc """
  Scylla Management Service
  """

  @behaviour WebProtocol.ScyllaManagementService

  # ----------------------------------------------------------------------------

  @doc """
  Get ClickHouse instances
  """
  @spec get_clickhouse_instances(
    api_key :: String.t() | nil,
    current_user :: Map.t() | nil
  ) :: DataProtocol.Collection.t(WebProtocol.ClickhouseInstance.t()) | no_return
  @impl WebProtocol.ScyllaManagementService
  def get_clickhouse_instances(
    api_key,
    current_user
  ) when
    (is_binary(api_key) or api_key === nil) and
    (is_map(current_user) or current_user === nil)
  do
    WebProtocol.Data.get_clickhouse_instances!(%{order_by: nil, order_dir: nil, limit: nil, offset: nil})
  end

  # ----------------------------------------------------------------------------

  @doc """
  Create a ClickHouse instance
  """
  @spec create_clickhouse_instance(
    api_key :: String.t() | nil,
    request_content :: WebProtocol.CreateClickhouseInstanceRequest.t(),
    current_user :: Map.t() | nil
  ) :: WebProtocol.ClickhouseInstance.t() | no_return
  @impl WebProtocol.ScyllaManagementService
  def create_clickhouse_instance(
    api_key,
    request_content,
    current_user
  ) when
    (is_binary(api_key) or api_key === nil) and
    is_struct(request_content, WebProtocol.CreateClickhouseInstanceRequest) and
    (is_map(current_user) or current_user === nil)
  do
    Scylla.create_clickhouse_instance!(request_content) |> WebProtocol.Data.get_clickhouse_instance!()
  end

  # ----------------------------------------------------------------------------

  @doc """
  Get a ClickHouse instance
  """
  @spec get_clickhouse_instance(
    id_or_code :: TypesProtocol.clickhouse_instance_id(),
    api_key :: String.t() | nil,
    current_user :: Map.t() | nil
  ) :: WebProtocol.ClickhouseInstance.t() | no_return
  @impl WebProtocol.ScyllaManagementService
  def get_clickhouse_instance(
    id_or_code,
    api_key,
    current_user
  ) when
    Scylla.ClickhouseInstanceId.is_clickhouse_instance_id(id_or_code) and
    (is_binary(api_key) or api_key === nil) and
    (is_map(current_user) or current_user === nil)
  do
    id_or_code |> WebProtocol.Data.get_clickhouse_instance!()
  end

  # ----------------------------------------------------------------------------

  @doc """
  Update a ClickHouse instance
  """
  @spec update_clickhouse_instance(
    id_or_code :: TypesProtocol.clickhouse_instance_id(),
    api_key :: String.t() | nil,
    request_content :: WebProtocol.UpdateClickhouseInstanceRequest.t(),
    current_user :: Map.t() | nil
  ) :: WebProtocol.ClickhouseInstance.t() | no_return
  @impl WebProtocol.ScyllaManagementService
  def update_clickhouse_instance(
    id_or_code,
    api_key,
    request_content,
    current_user
  ) when
    Scylla.ClickhouseInstanceId.is_clickhouse_instance_id(id_or_code) and
    (is_binary(api_key) or api_key === nil) and
    is_map(request_content) and
    (is_map(current_user) or current_user === nil)
  do
    Scylla.update_clickhouse_instance!(id_or_code, request_content) |> WebProtocol.Data.get_clickhouse_instance!()
  end

  # ----------------------------------------------------------------------------

  @doc """
  Delete a ClickHouse instance
  """
  @spec delete_clickhouse_instance(
    id_or_code :: TypesProtocol.clickhouse_instance_id(),
    api_key :: String.t() | nil,
    current_user :: Map.t() | nil
  ) :: any | no_return
  @impl WebProtocol.ScyllaManagementService
  def delete_clickhouse_instance(
    id_or_code,
    api_key,
    current_user
  ) when
    Scylla.ClickhouseInstanceId.is_clickhouse_instance_id(id_or_code) and
    (is_binary(api_key) or api_key === nil) and
    (is_map(current_user) or current_user === nil)
  do
    Scylla.delete_clickhouse_instance!(id_or_code) && true
  end

  # ----------------------------------------------------------------------------

  @doc """
  Get projects
  """
  @spec get_projects(
    api_key :: String.t() | nil,
    current_user :: Map.t() | nil
  ) :: DataProtocol.Collection.t(WebProtocol.Project.t()) | no_return
  @impl WebProtocol.ScyllaManagementService
  def get_projects(
    api_key,
    current_user
  ) when
    (is_binary(api_key) or api_key === nil) and
    (is_map(current_user) or current_user === nil)
  do
    WebProtocol.Data.get_projects!(%{order_by: nil, order_dir: nil, limit: nil, offset: nil})
  end

  # ----------------------------------------------------------------------------

  @doc """
  Create a project
  """
  @spec create_project(
    keep_db :: boolean,
    api_key :: String.t() | nil,
    request_content :: WebProtocol.CreateProjectRequest.t(),
    current_user :: Map.t() | nil
  ) :: WebProtocol.Project.t() | no_return
  @impl WebProtocol.ScyllaManagementService
  def create_project(
    keep_db,
    api_key,
    request_content,
    current_user
  ) when
    is_boolean(keep_db) and
    (is_binary(api_key) or api_key === nil) and
    is_struct(request_content, WebProtocol.CreateProjectRequest) and
    (is_map(current_user) or current_user === nil)
  do
    Scylla.create_project!(request_content, keep_db: keep_db) |> WebProtocol.Data.get_project!()
  end

  # ----------------------------------------------------------------------------

  @doc """
  Get a project
  """
  @spec get_project(
    id_or_code :: TypesProtocol.project_id(),
    api_key :: String.t() | nil,
    current_user :: Map.t() | nil
  ) :: WebProtocol.Project.t() | no_return
  @impl WebProtocol.ScyllaManagementService
  def get_project(
    id_or_code,
    api_key,
    current_user
  ) when
    Scylla.ProjectId.is_project_id(id_or_code) and
    (is_binary(api_key) or api_key === nil) and
    (is_map(current_user) or current_user === nil)
  do
    id_or_code |> WebProtocol.Data.get_project!()
  end

  # ----------------------------------------------------------------------------

  @doc """
  Update a project
  """
  @spec update_project(
    id_or_code :: TypesProtocol.project_id(),
    keep_db :: boolean,
    api_key :: String.t() | nil,
    request_content :: WebProtocol.UpdateProjectRequest.t(),
    current_user :: Map.t() | nil
  ) :: WebProtocol.Project.t() | no_return
  @impl WebProtocol.ScyllaManagementService
  def update_project(
    id_or_code,
    keep_db,
    api_key,
    request_content,
    current_user
  ) when
    Scylla.ProjectId.is_project_id(id_or_code) and
    is_boolean(keep_db) and
    (is_binary(api_key) or api_key === nil) and
    is_map(request_content) and
    (is_map(current_user) or current_user === nil)
  do
    Scylla.update_project!(id_or_code, request_content, keep_db: keep_db) |> WebProtocol.Data.get_project!()
  end

  # ----------------------------------------------------------------------------

  @doc """
  Delete a project
  """
  @spec delete_project(
    id_or_code :: TypesProtocol.project_id(),
    keep_db :: boolean,
    api_key :: String.t() | nil,
    current_user :: Map.t() | nil
  ) :: any | no_return
  @impl WebProtocol.ScyllaManagementService
  def delete_project(
    id_or_code,
    keep_db,
    api_key,
    current_user
  ) when
    Scylla.ProjectId.is_project_id(id_or_code) and
    is_boolean(keep_db) and
    (is_binary(api_key) or api_key === nil) and
    (is_map(current_user) or current_user === nil)
  do
    Scylla.delete_project!(id_or_code, keep_db: keep_db) && true
  end

  # ----------------------------------------------------------------------------

  @doc """
  Regenerate project key
  """
  @spec regenerate_project_key(
    id_or_code :: TypesProtocol.project_id(),
    key :: atom,
    api_key :: String.t() | nil,
    request_content :: DataProtocol.Empty.t(),
    current_user :: Map.t() | nil
  ) :: WebProtocol.Project.t() | no_return
  @impl WebProtocol.ScyllaManagementService
  def regenerate_project_key(
    id_or_code,
    key,
    api_key,
    request_content,
    current_user
  ) when
    Scylla.ProjectId.is_project_id(id_or_code) and
    is_atom(key) and
    (is_binary(api_key) or api_key === nil) and
    is_struct(request_content, DataProtocol.Empty) and
    (is_map(current_user) or current_user === nil)
  do
    Scylla.regenerate_project_key!(id_or_code, key) |> WebProtocol.Data.get_project!()
  end

  # ----------------------------------------------------------------------------

  @doc """
  Fetch last N project events
  """
  @spec fetch_project_events(
    id_or_code :: TypesProtocol.project_id(),
    count :: integer,
    api_key :: String.t() | nil,
    current_user :: Map.t() | nil
  ) :: [Igor.Json.json()] | no_return
  @impl WebProtocol.ScyllaManagementService
  def fetch_project_events(
    id_or_code,
    count,
    api_key,
    current_user
  ) when
    Scylla.ProjectId.is_project_id(id_or_code) and
    is_integer(count) and
    (is_binary(api_key) or api_key === nil) and
    (is_map(current_user) or current_user === nil)
  do
    Scylla.fetch_project_events!(id_or_code, count)
  end

  # ----------------------------------------------------------------------------

  @doc """
  Fetch migrations collection slice
  """
  @spec fetch_schema_migrations(
    id_or_code :: TypesProtocol.project_id(),
    order_by :: WebProtocol.SchemaMigrationOrderBy.t(),
    order_dir :: DataProtocol.OrderDirection.t(),
    offset :: non_neg_integer,
    limit :: non_neg_integer,
    api_key :: String.t() | nil,
    current_user :: Map.t() | nil
  ) :: DataProtocol.CollectionSlice.t(WebProtocol.SchemaMigration.t()) | no_return
  @impl WebProtocol.ScyllaManagementService
  def fetch_schema_migrations(
    id_or_code,
    order_by,
    order_dir,
    offset,
    limit,
    api_key,
    current_user
  ) when
    Scylla.ProjectId.is_project_id(id_or_code) and
    WebProtocol.SchemaMigrationOrderBy.is_schema_migration_order_by(order_by) and
    DataProtocol.OrderDirection.is_order_direction(order_dir) and
    is_integer(offset) and
    is_integer(limit) and
    (is_binary(api_key) or api_key === nil) and
    (is_map(current_user) or current_user === nil)
  do
    WebProtocol.Data.fetch_schema_migrations!(id_or_code |> Map.from_struct() |> Map.merge(%{order_by: order_by, order_dir: order_dir, limit: limit, offset: offset}))
  end

  # ----------------------------------------------------------------------------

  @doc """
  Fetch a migration
  """
  @spec fetch_schema_migration(
    id_or_code :: TypesProtocol.project_id(),
    migration_id :: integer,
    api_key :: String.t() | nil,
    current_user :: Map.t() | nil
  ) :: WebProtocol.SchemaMigration.t() | no_return
  @impl WebProtocol.ScyllaManagementService
  def fetch_schema_migration(
    id_or_code,
    migration_id,
    api_key,
    current_user
  ) when
    Scylla.ProjectId.is_project_id(id_or_code) and
    is_integer(migration_id) and
    (is_binary(api_key) or api_key === nil) and
    (is_map(current_user) or current_user === nil)
  do
    WebProtocol.Data.fetch_schema_migration!(id_or_code |> Map.from_struct() |> Map.merge(%{migration_id: migration_id}))
  end

  # ----------------------------------------------------------------------------

  @doc """
  Fetch list of backup fields
  """
  @spec get_backup_fields(
    id_or_code :: TypesProtocol.project_id(),
    order_by :: WebProtocol.BackupFieldOrderBy.t(),
    order_dir :: DataProtocol.OrderDirection.t(),
    offset :: non_neg_integer,
    limit :: non_neg_integer,
    api_key :: String.t() | nil,
    current_user :: Map.t() | nil
  ) :: DataProtocol.CollectionSlice.t(String.t()) | no_return
  @impl WebProtocol.ScyllaManagementService
  def get_backup_fields(
    id_or_code,
    order_by,
    order_dir,
    offset,
    limit,
    api_key,
    current_user
  ) when
    Scylla.ProjectId.is_project_id(id_or_code) and
    WebProtocol.BackupFieldOrderBy.is_backup_field_order_by(order_by) and
    DataProtocol.OrderDirection.is_order_direction(order_dir) and
    is_integer(offset) and
    is_integer(limit) and
    (is_binary(api_key) or api_key === nil) and
    (is_map(current_user) or current_user === nil)
  do
    backup_fields = Scylla.get_ingestion_schema!(id_or_code)
      |> elem(0)
      |> Stream.filter(fn {name, _spec} -> String.contains?(name, "__backup_") end)
      |> Enum.map(fn {name, _spec} -> name end)
    backup_fields
      |> Enum.map(fn
        x when order_by == :name -> {x, x}
        x when order_by == :field_name -> {x |> String.split("__backup_") |> List.first(), x}
        x when order_by == :migration -> {x |> String.split("__backup_") |> Enum.at(1), x}
      end)
      |> List.keysort(0, order_dir)
      |> Enum.map(&elem(&1, 1))
      |> Stream.drop(offset)
      |> Enum.take(limit)
      |> then(& %DataProtocol.CollectionSlice{items: &1, total: length(backup_fields)})
  end

  # ----------------------------------------------------------------------------

  @doc """
  Drop backup fields by name
  """
  @spec drop_backup_fields(
    id_or_code :: TypesProtocol.project_id(),
    api_key :: String.t() | nil,
    request_content :: [String.t()],
    current_user :: Map.t() | nil
  ) :: any | no_return
  @impl WebProtocol.ScyllaManagementService
  def drop_backup_fields(
    id_or_code,
    api_key,
    request_content,
    current_user
  ) when
    Scylla.ProjectId.is_project_id(id_or_code) and
    (is_binary(api_key) or api_key === nil) and
    is_list(request_content) and
    (is_map(current_user) or current_user === nil)
  do
    Scylla.drop_backup_fields!(id_or_code, request_content)
  end

end
