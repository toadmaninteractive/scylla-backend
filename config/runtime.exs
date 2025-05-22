import Config

# database

config :scylla, Repo,
  username: System.fetch_env!("DB_USER"),
  password: System.fetch_env!("DB_PASS"),
  database: System.fetch_env!("DB_NAME"),
  hostname: System.fetch_env!("DB_HOST")

# web server

config :scylla, :web,
  ip: System.fetch_env!("BACKEND_IP"),
  port: System.fetch_env!("BACKEND_PORT") |> String.to_integer,
  session: [
    secret: System.fetch_env!("BACKEND_SESSION_SECRET"),
    encryption_salt: System.fetch_env!("BACKEND_SESSION_ENCRYPTION_SALT"),
    signing_salt: System.fetch_env!("BACKEND_SESSION_SIGNING_SALT")
  ],
  api_keys: System.fetch_env!("BACKEND_API_KEYS") |> String.split(",")

if config_env() != :client do
  cors_origins = Regex.split(~r{\s*,\s*}, System.fetch_env!("FRONTEND_SERVER_CORS"), trim: true)
  config :scylla, :web,
    cors: [
      fallback_origin: cors_origins |> List.first,
      allowed_origins: cors_origins
    ]
end

# ldap

if config_env() != :client do
  config :exldap, :settings,
    server: System.fetch_env!("LDAP_HOST"),
    port: System.fetch_env!("LDAP_PORT") |> String.to_integer,
    ssl: System.fetch_env!("LDAP_SSL") === "true",
    user_dn: System.fetch_env!("LDAP_USER"),
    password: System.fetch_env!("LDAP_PASS"),
    base: System.fetch_env!("LDAP_BASE")
end

# clickhouse

config :scylla, :clickhouse,
  table: System.fetch_env!("CLICKHOUSE_TABLE"),
  save_events_directory: System.fetch_env!("CLICKHOUSE_SAVE_EVENTS_DIR"),
  transient_error_codes: System.fetch_env!("CLICKHOUSE_TRANSIENT_ERROR_CODES") |> String.split(",", trim: true) |> Enum.map(&String.to_integer/1)
