defmodule Scylla.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  @app :scylla

  use Application

  @impl true
  def start(_type, _args) do
    LoggerBackends.add({LoggerFileBackend, :error_log}, Util.config!(:logger, [:error_log]))
    children = [
      # Starts a worker by calling: Store.Worker.start_link(arg)
      # {Scylla.Worker, arg}
      # start repository
      Repo,
      # start scheduler
      Scheduler,
      # start http endpoint
      {Bandit,
        plug: Web.Server,
        ip: case :inet.parse_address(String.to_charlist(Util.config!(@app, [:web, :ip]))) do
          {:ok, ip} -> ip
        end,
        port: Util.config!(@app, [:web, :port]),
      },
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
