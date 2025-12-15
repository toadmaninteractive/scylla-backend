defmodule IngestProtocol.ScyllaIngestionService.Impl do

  require Scylla.ProjectId

  @behaviour IngestProtocol.ScyllaIngestionService

  # ----------------------------------------------------------------------------

  @doc """
  Push events to project database
  """
  @spec send_events(
    project_id_or_code :: TypesProtocol.project_id(),
    api_key :: String.t() | nil,
    request_content :: IngestProtocol.Envelope.t(),
    current_user :: Map.t() | nil
  ) :: IngestProtocol.IngestorResponse.t() | no_return
  @impl IngestProtocol.ScyllaIngestionService
  def send_events(
    project_id_or_code,
    api_key,
    request_content,
    current_user
  ) when
    Scylla.ProjectId.is_project_id(project_id_or_code) and
    (is_binary(api_key) or api_key === nil) and
    is_struct(request_content, IngestProtocol.Envelope) and
    (is_map(current_user) or current_user === nil)
  do
    {ingested_count, errors} = Scylla.push_events!(project_id_or_code, request_content.events)
    %IngestProtocol.IngestorResponse{ingested_count: ingested_count, errors: errors}
  end

  # ----------------------------------------------------------------------------

  #@doc """
  #Get project schema
  #"""
  #@spec get_schema(
  #  project_id_or_code :: TypesProtocol.project_id(),
  #  api_key :: String.t() | nil,
  #  current_user :: Map.t() | nil
  #) :: IngestProtocol.OldSchemaResponse.t() | no_return
  #@impl IngestProtocol.ScyllaIngestionService
  #def get_schema(
  #  project_id_or_code,
  #  api_key,
  #  current_user
  #) when
  #  Scylla.ProjectId.is_project_id(project_id_or_code) and
  #  (is_binary(api_key) or api_key === nil) and
  #  (is_map(current_user) or current_user === nil)
  #do
  #  {fields, order_by} = Scylla.get_ingestion_schema!(project_id_or_code)
  #  %IngestProtocol.OldSchemaResponse{schema: fields |> Enum.into(%{}), order: fields |> Enum.map(& elem(&1, 0)), order_by: order_by}
  #end

  # ----------------------------------------------------------------------------

  @doc """
  Update project schema
  """
  @spec update_schema(
    project_id_or_code :: TypesProtocol.project_id(),
    force :: boolean,
    api_key :: String.t() | nil,
    request_content :: IgorSchema.Schema.t(),
    current_user :: Map.t() | nil
  ) :: any | no_return
  @impl IngestProtocol.ScyllaIngestionService
  def update_schema(
    project_id_or_code,
    force,
    api_key,
    request_content,
    current_user
  ) when
    Scylla.ProjectId.is_project_id(project_id_or_code) and
    is_boolean(force) and
    (is_binary(api_key) or api_key === nil) and
    is_struct(request_content, IgorSchema.Schema) and
    (is_map(current_user) or current_user === nil)
  do
    Scylla.update_clickhouse_schema!(project_id_or_code, request_content, force: force) && true
  end

  # ----------------------------------------------------------------------------

end
