defmodule Web.Router do
  @moduledoc """
  HTTP Server Router
  """

  use Plug.Router
  use Plug.ErrorHandler

  plug :match
  plug :dispatch

  # --- START of routes --------------------------------------------------------

  forward "/ingest", to: IngestProtocol.ScyllaIngestionService
  forward "/manage", to: WebProtocol.ScyllaManagementService
  forward "/auth", to: WebProtocol.ScyllaAuthService

  # --- END of routes ----------------------------------------------------------

  # catchall route
  match _, do: send_resp(conn, 404, "")

  #-----------------------------------------------------------------------------
  # helpers
  #-----------------------------------------------------------------------------

  def read_may_be_compressed_body(conn, opts \\ []) do
    # {:more, "", conn}
    # IO.inspect({:boo, opts})
    case read_body(conn, opts) do
      {:ok, body, conn} ->
        # IO.inspect({:bo?, body})
        encoding = List.first(get_req_header(conn, "content-encoding"))
        body = cond do
          encoding in ["gzip", "x-gzip"] and String.starts_with?(body, <<31, 139, 8>>) -> :zlib.gunzip(body)
          encoding in ["deflate"] -> :zlib.unzip(body)
          true -> body
        end
        # IO.inspect({:bo!, body})
        {:ok, body, conn}
      {:error, :too_large, _conn} ->
        raise Plug.Parsers.RequestTooLargeError, message: "The request is too large"
      other -> other
    end
  end

  def read_may_be_multipart_body(conn, opts \\ []) do
    case conn |> get_req_header("content-type") |> List.first() |> Plug.Conn.Utils.content_type() do
      {:ok, "multipart", "form-data", _} -> read_multipart_body(conn, opts)
      _ -> read_body(conn, opts)
    end
  end

  defp read_multipart_body(conn, opts) do
    parser_opts = Plug.Parsers.MULTIPART.init(opts)
    case Plug.Parsers.MULTIPART.parse(conn, "multipart", "form-data", [], parser_opts) do
      {:ok, params, conn} ->
        read_files = opts[:read_files]
        params = params |> Enum.map(fn
          {k, %Plug.Upload{path: path} = v} ->
            case read_files do
              true -> {k |> String.replace_suffix("_file", ""), File.read!(path)}
              list when is_list(list) -> {(if k in list, do: String.replace_suffix(k, "_file", ""), else: k), File.read!(path)}
              _ -> {k, %{"content_type" => v.content_type, "filename" => v.filename, "path" => path}}
            end
          # TODO: find more robust unescaper
          {k, v} -> {k, v |> String.replace(~r/\\\w/, fn "\\n" -> "\n"; "\\r" -> "\r" end)}
        end) |> Enum.into(%{})
        {:ok, params, conn}
      {:error, :too_large, _conn} ->
        {_, limit, _, _} = parser_opts
        raise Plug.Parsers.RequestTooLargeError, message: "The request is larger #{limit} octets"
    end
  end

  #-----------------------------------------------------------------------------
  # middleware
  #-----------------------------------------------------------------------------

  @impl Plug.ErrorHandler
  def handle_errors(conn, %{kind: :error, reason: %FunctionClauseError{}, stack: [{m, f, a, _} | _]}) do
    require Logger
    Logger.emergency("encoder failure", data: %{module: m, function: f, args: a}, domain: [:unhandled])
    report_exception(conn)
  end
  def handle_errors(conn, %{kind: :error, reason: reason, stack: stacktrace}) do
    case Plug.Exception.status(reason) do
      500 ->
        require Logger
        Logger.emergency("unhandled exception", data: %{exception: reason, stacktrace: stacktrace}, domain: [:unhandled])
        report_exception(conn)
      status_code ->
        conn
          # |> Plug.Conn.send_resp(status_code, Exception.format(:error, reason, []))
          |> Plug.Conn.send_resp(status_code, Exception.message(reason))
    end
  end

  #-----------------------------------------------------------------------------
  # internal functions
  #-----------------------------------------------------------------------------

  defp report_exception(conn) do
    conn
      |> send_resp(conn.status, "Unhandled exception occured.\nPlease do contact developers.\nRequest ID: #{Logger.metadata[:request_id]}")
  end

end
