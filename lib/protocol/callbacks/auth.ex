defmodule WebProtocol.ScyllaAuthService.Impl do

  @moduledoc """
  Scylla Authentication Service
  """

  @behaviour WebProtocol.ScyllaAuthService

  # ----------------------------------------------------------------------------

  @doc """
  TODO: annotate WebProtocol.ScyllaAuthService.Login
  """
  @spec login(
    conn :: Plug.Conn.t(),
    request_content :: WebProtocol.LoginRequest.t(),
    current_user :: Map.t() | nil
  ) :: {Plug.Conn.t(), WebProtocol.UserProfile.t()} | no_return
  @impl WebProtocol.ScyllaAuthService
  def login(
    conn,
    request_content,
    current_user
  ) when
    is_map(conn) and
    is_struct(request_content, WebProtocol.LoginRequest) and
    (is_map(current_user) or current_user === nil)
  do
    %WebProtocol.LoginRequest{username: username, password: password} = request_content
    case Auth.Ldap.check(username, password) do
      {:ok, %{uid: uid, cn: username}} ->
        current_user = %{role: "scylla_web", uid: uid, username: username}
        {conn |> Plug.Conn.put_session(:api, current_user), get_my_profile(current_user)}
      {:error, _} ->
        raise DataProtocol.BadRequestError, error: :invalid_user_or_password
    end
  end

  # ----------------------------------------------------------------------------

  @doc """
  TODO: annotate WebProtocol.ScyllaAuthService.Logout
  """
  @spec logout(
    conn :: Plug.Conn.t(),
    current_user :: Map.t() | nil
  ) :: Plug.Conn.t() | no_return
  @impl WebProtocol.ScyllaAuthService
  def logout(
    conn,
    current_user
  ) when
    is_map(conn) and
    (is_map(current_user) or current_user === nil)
  do
    conn |> Plug.Conn.delete_session(:api)
  end

  # ----------------------------------------------------------------------------

  @doc """
  TODO: annotate WebProtocol.ScyllaAuthService.GetMyProfile
  """
  @spec get_my_profile(
    current_user :: Map.t() | nil
  ) :: WebProtocol.UserProfile.t() | no_return
  @impl WebProtocol.ScyllaAuthService
  def get_my_profile(
    current_user
  ) when
    (is_map(current_user) or current_user === nil)
  do
    %WebProtocol.UserProfile{role: current_user.role, user_id: current_user.uid, username: current_user.username}
  end

end
