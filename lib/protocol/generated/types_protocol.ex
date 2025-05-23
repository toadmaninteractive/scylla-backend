# @author Igor compiler
# @doc Compiler version: igorc 2.1.4
# DO NOT EDIT THIS FILE - it is machine generated

defmodule TypesProtocol do

  defmodule Stub do

    defstruct []

    @type t :: %Stub{}

    @spec from_json!(Igor.Json.json()) :: t()
    def from_json!(%{}), do: %Stub{}

    @spec to_json!(t()) :: Igor.Json.json()
    def to_json!(%Stub{}), do: %{}

  end

  @type uuid :: String.t()

  @type project_id :: String.t()

  @type clickhouse_instance_id :: String.t()

  @type project_schema :: String.t()

end
