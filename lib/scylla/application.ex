defmodule Scylla.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  @app :scylla

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: Store.Worker.start_link(arg)
      # {Scylla.Worker, arg}
      # start repository
      Repo,
      # start scheduler
      Scheduler,
      # start http endpoint
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: Web.Server,
        # see https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html#module-options
        options: [
          ip: case :inet.parse_address(String.to_charlist(Util.config(@app, [:web, :ip], "127.0.0.1"))) do
            {:ok, ip} -> ip
          end,
          port: Util.config(@app, [:web, :port]),
          compress: true,
          # NB: Plug punts on websockets by default (?) so we have to provide custom dispatcher
          dispatch: [
            {:_, [
              # {"/ws", Web.WebSocket, handler: Web.WebSocket.Impl},
              {:_, Plug.Cowboy.Handler, {Web.Server, []}}
            ]}
          ],
        ]
      ),
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Store.Supervisor]
    link = Supervisor.start_link(children, opts)
    require Logger
    Logger.info("#{__MODULE__} started", domain: [:http])
    link
  end
end
