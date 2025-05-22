defmodule Queries do

  use AyeSQL, runner: AyeSQLAuthorizedQueryRunner, repo: Repo

  defqueries("queries.sql")

end
