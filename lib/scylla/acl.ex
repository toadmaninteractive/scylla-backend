defmodule ACL do

  @app :scylla

  # ----------------------------------------------------------------------------

  def can!(subject, action, object \\ %{})
  def can!(subject, action, object) do
    unless can?(subject, action, object), do: raise DataProtocol.ForbiddenError
  end

  # ----------------------------------------------------------------------------

  def can?(%{role: "scylla_ext", key: key}, action, %{key_su: key_su, key_rw: key_rw}) when is_binary(key) and action in [
    "IngestProtocol.ScyllaIngestionService.SendEvents",
    "IngestProtocol.ScyllaIngestionService.GetSchema",
    "IngestProtocol.ScyllaIngestionService.UpdateSchema",
  ], do: key in api_keys() or key === key_su or key === key_rw

  def can?(%{role: "scylla_ext", key: key}, action, _) when is_binary(key) and action in [
    # "IngestProtocol.ScyllaIngestionService.SendEvents",
    # "IngestProtocol.ScyllaIngestionService.GetSchema",
    # "IngestProtocol.ScyllaIngestionService.UpdateSchema",
    "WebProtocol.ScyllaManagementService.GetClickhouseInstances",
    "WebProtocol.ScyllaManagementService.CreateClickhouseInstance",
    "WebProtocol.ScyllaManagementService.GetClickhouseInstance",
    "WebProtocol.ScyllaManagementService.UpdateClickhouseInstance",
    "WebProtocol.ScyllaManagementService.DeleteClickhouseInstance",
    "WebProtocol.ScyllaManagementService.GetProjects",
    "WebProtocol.ScyllaManagementService.CreateProject",
    "WebProtocol.ScyllaManagementService.GetProject",
    "WebProtocol.ScyllaManagementService.UpdateProject",
    "WebProtocol.ScyllaManagementService.DeleteProject",
    "WebProtocol.ScyllaManagementService.RegenerateProjectKey",
    "WebProtocol.ScyllaManagementService.FetchProjectEvents",
    "WebProtocol.ScyllaManagementService.FetchSchemaMigrations",
    "WebProtocol.ScyllaManagementService.FetchSchemaMigration",
    "WebProtocol.ScyllaManagementService.GetBackupFields",
    "WebProtocol.ScyllaManagementService.DropBackupFields",
    # "WebProtocol.ScyllaAuthService.Login",
    # "WebProtocol.ScyllaAuthService.Logout",
    # "WebProtocol.ScyllaAuthService.GetMyProfile",
  ], do: key in api_keys()

  def can?(%{role: "scylla_web", uid: uid}, action, _) when not is_nil(uid) and action in [
    "IngestProtocol.ScyllaIngestionService.SendEvents",
    "IngestProtocol.ScyllaIngestionService.GetSchema",
    "IngestProtocol.ScyllaIngestionService.UpdateSchema",
    "WebProtocol.ScyllaManagementService.GetClickhouseInstances",
    "WebProtocol.ScyllaManagementService.CreateClickhouseInstance",
    "WebProtocol.ScyllaManagementService.GetClickhouseInstance",
    "WebProtocol.ScyllaManagementService.UpdateClickhouseInstance",
    "WebProtocol.ScyllaManagementService.DeleteClickhouseInstance",
    "WebProtocol.ScyllaManagementService.GetProjects",
    "WebProtocol.ScyllaManagementService.CreateProject",
    "WebProtocol.ScyllaManagementService.GetProject",
    "WebProtocol.ScyllaManagementService.UpdateProject",
    "WebProtocol.ScyllaManagementService.DeleteProject",
    "WebProtocol.ScyllaManagementService.RegenerateProjectKey",
    "WebProtocol.ScyllaManagementService.FetchProjectEvents",
    "WebProtocol.ScyllaManagementService.FetchSchemaMigrations",
    "WebProtocol.ScyllaManagementService.FetchSchemaMigration",
    "WebProtocol.ScyllaManagementService.GetBackupFields",
    "WebProtocol.ScyllaManagementService.DropBackupFields",
    "WebProtocol.ScyllaAuthService.Login",
    "WebProtocol.ScyllaAuthService.Logout",
    "WebProtocol.ScyllaAuthService.GetMyProfile",
  ], do: true

  def can?(nil, action, _) when action in [
    "WebProtocol.ScyllaAuthService.Login",
  ], do: true

  def can?(_, _, _), do: false

  # ----------------------------------------------------------------------------

  defp api_keys(), do: Application.fetch_env!(@app, :web)[:api_keys]

end
