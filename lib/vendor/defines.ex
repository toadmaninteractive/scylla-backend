Postgrex.Types.define(Repo.PostgresTypes, [
  {Postgrex.Extensions.UUIDString, [decode_binary: :copy]},
  {Postgrex.Extensions.LTree, [decode_copy: :copy]},
] ++ Ecto.Adapters.Postgres.extensions())
