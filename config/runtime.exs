import Config

# merge json config

#conf = File.read!(System.get_env("CONFIG_PATH", "config.json")) |> Jason.decode!(keys: :atoms)
conf = System.get_env("CONFIG_PATH", "config.yaml")
  |> YamlElixir.read_from_file!()
  |> Map.get("hermes")
  |> ConfigProtocol.Config.from_json!()

  # TODO?: is protocol capable of parsing record into keyword list?
  |> Map.from_struct()
  |> Enum.map(fn
    {k, v} when is_struct(v) -> {k, v |> Map.from_struct() |> Map.to_list()}
    {k, v} when is_map(v) -> {k, v |> Map.to_list()}
    {k, v} -> {k, v}
  end)
  |> update_in([:web, :session], & &1 |> Map.from_struct() |> Map.to_list())
  |> IO.inspect(label: "CONF")

# database

config :scylla, Repo, conf[:db]

# web server

config :scylla, :web, conf[:web]

# ldap

if config_env() != :client do
  config :exldap, :settings, conf[:ldap]
end

# scheduler

config :scylla, Scheduler, jobs: (
  Util.config!(:scylla, [Scheduler, :jobs]) ++
  Enum.map(conf[:jobs], fn {name, %{schedule: schedule, extended: extended} = job} ->
    schedule = case extended do
      # second granularity
      true -> {:extended, schedule}
      _ -> schedule
    end
    [name: name, schedule: schedule, task: {job.module && String.to_atom("Elixir.#{job.module}") || Scylla, job.function || name, job.arguments}]
  end)
)

# clickhouse

config :scylla, :clickhouse, conf[:clickhouse]
