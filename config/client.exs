import Config

config :logger,
  backends: [:console, {LoggerFileBackend, :warn_log}],
  compile_time_purge_matching: [
    [domain: [:http]],
    [domain: [:rpc], level_lower_than: :warn],
  ]

config :logger, :console,
  level: :warn,
  metadata: [:domain, :data, :request_id],
  format: {Logger.Formatter.Vd, :format},
  truncate: :infinity

config :logger, :warn_log,
  path: "log/warn.txt",
  rotate: %{max_bytes: 10000000, keep: 10},
  level: :warn,
  format: {Logger.Formatter.Vd, :format},
  metadata: [:domain, :data, :request_id]
