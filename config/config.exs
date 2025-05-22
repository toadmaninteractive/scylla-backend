import Config

#
# logger
#

config :logger,
  backends: [:console, {LoggerFileBackend, :error_log}],
  # backends: [:console, {LoggerFileBackend, :error_log}],
  compile_time_purge_matching: [
    [domain: [:http]],
    # [domain: [:rpc], level_lower_than: :error],
  ]

config :logger, :console,
  level: :warn,
  level: config_env() == :prod && :warn || :info,
  metadata: [:domain, :data, :request_id],
  format: {Logger.Formatter.Vd, :format},
  truncate: :infinity

config :logger, :error_log,
  path: "log/error.txt",
  rotate: %{max_bytes: 10000000, keep: 10},
  level: :error,
  format: {Logger.Formatter.Vd, :format},
  metadata: [:domain, :data, :request_id]

#
# database
#

config :scylla,
  ecto_repos: [Repo]

config :scylla, Repo,
  types: Repo.PostgresTypes,
  # migration_primary_key: [type: :binary_id],
  migration_timestamps: [inserted_at: :created_at],
  timeout: 30000,
  show_sensitive_data_on_connection_error: false,
  pool_size: 10,
  queue_target: 5000,
  parameters: [
    application_name: "scylla-#{config_env()}",
  ],
  log: false

#
# scheduler
#

config :scylla, Scheduler,
  debug_logging: false,
  overlap: false,
  jobs: [
    migrate: [schedule: "@reboot", task: {Repo, :migrate, []}],
    compile_parsers: [schedule: "@reboot", task: {Scylla, :precompile_parsers, []}],
    setup_saved_events: [schedule: "@reboot", task: {Scylla, :setup_saved_events, []}],
    resend_saved_events: [schedule: {:extended, "*/15"}, task: {Scylla, :resend_saved_events, []}],
  ]

#
# web server
#

config :plug_cowboy,
  log_exceptions_with_status_code: []

config :scylla, :web,
  session: [
    store: :cookie,
    key: "x_scylla_sid",
    secret: "TODO: place to BACKEND_SESSION_SECRET environment",
    encryption_salt: "TODO: place to BACKEND_SESSION_ENCRYPTION_SALT environment",
    signing_salt: "TODO: place to BACKEND_SESSION_SIGNING_SALT environment",
    key_length: 64,
    max_age: 365 * 86400,
    log: false
  ]

#
# private portion
#

#
# environment specific config
#
import_config "#{config_env()}.exs"
