defmodule Web.Server do
  @moduledoc """
  HTTP Server
  """

  @app :scylla

  use Plug.Builder

  # plug Plug.Static,
  #   at: "/",
  #   from: @app,
  #   gzip: false,
  #   only: ~w(images css fonts js favicon.ico robots.txt thumbnail.png)

  # assign log id
  plug Plug.RequestId, http_header: "x-log-id"
  # no cache
  plug :no_cache
  # cors
  plug :cors
  # logger
  plug :trace, builder_opts()

  # session
  plug :put_secret_key_base
  plug Plug.Session, Util.config(@app, [:web, :session])
  plug :extract_session

  # plug :put_context

  # delegate to router
  plug Web.Router

  #-----------------------------------------------------------------------------
  # middleware
  #-----------------------------------------------------------------------------

  defp no_cache(conn, _opts) do
    conn
      |> put_resp_header("cache-control", "no-cache, no-store, must-revalidate")
      |> put_resp_header("pragma", "no-cache")
      |> put_resp_header("expires", "0")
  end

  # TODO: move completely to reverse proxy
  defp cors(%{method: "OPTIONS"} = conn, _opts) do
    conn
      |> put_resp_header("access-control-allow-origin", cors_origin(conn))
      |> put_resp_header("access-control-allow-credentials", "true")
      |> put_resp_header("access-control-allow-methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS")
      |> put_resp_header("access-control-allow-headers", "cookie, content-type, x-api-key, x-session-id")
      |> put_resp_header("access-control-max-age", "864000000")
      |> put_resp_header("vary", "accept-encoding, origin")
      |> put_resp_header("keep-alive", "timeout=2, max=100")
      |> put_resp_header("connection", "keep-alive")
      |> send_resp(204, "")
      |> halt
  end
  defp cors(conn, _opts) do
    conn
      |> put_resp_header("access-control-allow-origin", cors_origin(conn))
      |> put_resp_header("access-control-allow-credentials", "true")
  end

  defp put_secret_key_base(conn, _) do
    put_in conn.secret_key_base, Util.config(@app, [:web, :session, :secret])
  end

  defp extract_session(conn, _opts) do
    conn = conn
      |> fetch_session()
    # conn
    #   |> put_private(:session, get_session(conn, :api))
    # TODO: replace with user getter
    current_user = get_session(conn, :api)
    conn
      |> assign(:current_user, current_user)
  end

  # defp put_context(conn, _opts) do
  #   # TODO: replace with user getter
  #   current_user = conn.private[:session]
  #   conn
  #     |> assign(:current_user, current_user)
  # end

  # TODO: replace with telemetry
  defp trace(conn, opts) do
    if opts[:log] === false do
      conn
    else
      require Logger
      start = :os.timestamp()
      conn = conn
        |> fetch_query_params
        |> register_before_send(fn conn ->
            stop = :os.timestamp()
            duration = Float.round(:timer.now_diff(stop, start) / 1000, 3)
            Logger.debug("http_res: #{conn.method} #{conn.request_path} status=#{conn.status} duration=#{duration}ms", data: %{status: conn.status, duration: duration}, domain: [:http])
            conn
          end)
      Logger.debug("http_req: #{conn.method} #{conn.request_path}", data: %{params: conn.params}, domain: [:http])
      conn
    end
  end

  #-----------------------------------------------------------------------------
  # internal functions
  #-----------------------------------------------------------------------------

  defp cors_origin(conn) do
    origin = to_string(get_req_header(conn, "origin"))
    cors = Util.config(@app, [:web, :cors])
    case cors[:allowed_origins] do
      allowed_origins when is_list(allowed_origins) ->
        case origin in allowed_origins do
          true -> origin
          false -> cors[:fallback_origin] || origin
        end
      _ -> cors[:fallback_origin] || origin
    end
  end

  #-----------------------------------------------------------------------------

end
