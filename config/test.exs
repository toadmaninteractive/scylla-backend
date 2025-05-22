import Config

# logger
config :logger,
  compile_time_purge_matching: [
    [level_lower_than: :warning],
  ]

# database
config :scylla, Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  url: "ecto://postgres:postgres@localhost/scylla_test"

# scheduler
config :scylla, Scheduler,
  debug_logging: false,
  overlap: false,
  jobs: []

# web server
config :scylla, :web,
  port: 39902
