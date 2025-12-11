defmodule Scylla.MixProject do
  use Mix.Project

  def project do
    [
      app: :scylla,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod or Mix.env() == :client,
      aliases: aliases(),
      deps: deps(),
      releases: releases(),
      default_release: :server,
      consolidate_protocols: Mix.env() != :dev
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: case Mix.env() do
        :client -> [:logger, :logger_file_backend, :crypto, :httpoison]
        _ -> [:logger, :logger_file_backend, :crypto, :httpoison, :exldap]
      end,
      mod: {Scylla.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.4"},
      {:bandit, "~> 1.8"},
      {:ayesql, "~> 1.1.0"},
      {:ecto, "~> 3.13"},
      {:ecto_sql, "~> 3.13"},
      {:postgrex, ">= 0.0.0"},
      {:httpoison, "~> 2.2"},
      {:quantum, "~> 3.5"},
      {:logger_backends, "~> 1.0"},
      {:logger_file_backend, "~> 0.0.12"},
      {:exldap, "~> 0.6"},
      {:yaml_elixir, "~> 2.11"},

      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "local.prerequisites": ["local.hex --force", "local.rebar --force"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end

  # Run "mix help release" to learn about releases.
  defp releases do
    [
        server: [
          include_executables_for: [:unix],
          applications: [runtime_tools: :permanent],
          validate_compile_env: false
        ],
        server_windows: [
          include_executables_for: [:windows],
          applications: [runtime_tools: :permanent]
        ]
    ]
  end
end
