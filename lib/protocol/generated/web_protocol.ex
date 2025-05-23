# @author Igor compiler
# @doc Compiler version: igorc 2.1.4
# DO NOT EDIT THIS FILE - it is machine generated

defmodule WebProtocol do

  defmodule LoginRequest do

    @enforce_keys [:username, :password]
    defstruct [username: nil, password: nil]

    @type t :: %LoginRequest{username: String.t(), password: String.t()}

    @spec from_json!(Igor.Json.json()) :: t()
    def from_json!(json) do
      username = Igor.Json.parse_field!(json, "username", :string)
      password = Igor.Json.parse_field!(json, "password", :string)
      %LoginRequest{username: username, password: password}
    end

    @spec to_json!(t()) :: Igor.Json.json()
    def to_json!(args) do
      %{username: username, password: password} = args
      %{
        "username" => Igor.Json.pack_value(username, :string),
        "password" => Igor.Json.pack_value(password, :string)
      }
    end

  end

  defmodule LoginResponse do

    @enforce_keys [:role, :user_id, :username, :session_id]
    defstruct [role: nil, user_id: nil, username: nil, session_id: nil]

    @type t :: %LoginResponse{role: String.t(), user_id: String.t(), username: String.t(), session_id: String.t()}

    @spec from_json!(Igor.Json.json()) :: t()
    def from_json!(json) do
      role = Igor.Json.parse_field!(json, "role", :string)
      user_id = Igor.Json.parse_field!(json, "user_id", :string)
      username = Igor.Json.parse_field!(json, "username", :string)
      session_id = Igor.Json.parse_field!(json, "session_id", :string)
      %LoginResponse{
        role: role,
        user_id: user_id,
        username: username,
        session_id: session_id
      }
    end

    @spec to_json!(t()) :: Igor.Json.json()
    def to_json!(args) do
      %{
        role: role,
        user_id: user_id,
        username: username,
        session_id: session_id
      } = args
      %{
        "role" => Igor.Json.pack_value(role, :string),
        "user_id" => Igor.Json.pack_value(user_id, :string),
        "username" => Igor.Json.pack_value(username, :string),
        "session_id" => Igor.Json.pack_value(session_id, :string)
      }
    end

  end

  defmodule LoginError do

    @type t ::
      :invalid_user_or_password # Invalid username or password

    defguard is_login_error(value) when value === :invalid_user_or_password

    @spec from_string!(String.t()) :: t()
    def from_string!("invalid_user_or_password"), do: :invalid_user_or_password

    @spec to_string!(t()) :: String.t()
    def to_string!(:invalid_user_or_password), do: "invalid_user_or_password"

    @spec from_json!(String.t()) :: t()
    def from_json!("invalid_user_or_password"), do: :invalid_user_or_password

    @spec to_json!(t()) :: String.t()
    def to_json!(:invalid_user_or_password), do: "invalid_user_or_password"

  end

  defmodule UserProfile do

    @enforce_keys [:role, :user_id, :username]
    defstruct [role: nil, user_id: nil, username: nil]

    @type t :: %UserProfile{role: String.t(), user_id: String.t(), username: String.t()}

    @spec from_json!(Igor.Json.json()) :: t()
    def from_json!(json) do
      role = Igor.Json.parse_field!(json, "role", :string)
      user_id = Igor.Json.parse_field!(json, "user_id", :string)
      username = Igor.Json.parse_field!(json, "username", :string)
      %UserProfile{role: role, user_id: user_id, username: username}
    end

    @spec to_json!(t()) :: Igor.Json.json()
    def to_json!(args) do
      %{role: role, user_id: user_id, username: username} = args
      %{
        "role" => Igor.Json.pack_value(role, :string),
        "user_id" => Igor.Json.pack_value(user_id, :string),
        "username" => Igor.Json.pack_value(username, :string)
      }
    end

  end

  defmodule ClickhouseInstance do

    @moduledoc """
    ClickHouse instances
    """
    @enforce_keys [:id, :code, :name, :uri, :username, :password, :rev, :created_at, :updated_at]
    defstruct [id: nil, code: nil, name: nil, uri: nil, username: nil, password: nil, rev: nil, created_at: nil, updated_at: nil]

    @type t :: %ClickhouseInstance{id: integer, code: String.t(), name: String.t(), uri: String.t(), username: String.t(), password: String.t(), rev: integer, created_at: DateTime.t(), updated_at: DateTime.t()}

    @spec from_json!(Igor.Json.json()) :: t()
    def from_json!(json) do
      id = Igor.Json.parse_field!(json, "id", :long)
      code = Igor.Json.parse_field!(json, "code", :string)
      name = Igor.Json.parse_field!(json, "name", :string)
      uri = Igor.Json.parse_field!(json, "uri", :string)
      username = Igor.Json.parse_field!(json, "username", :string)
      password = Igor.Json.parse_field!(json, "password", :string)
      rev = Igor.Json.parse_field!(json, "rev", :int)
      created_at = Igor.Json.parse_field!(json, "created_at", {:custom, Util.DateTime})
      updated_at = Igor.Json.parse_field!(json, "updated_at", {:custom, Util.DateTime})
      %ClickhouseInstance{
        id: id,
        code: code,
        name: name,
        uri: uri,
        username: username,
        password: password,
        rev: rev,
        created_at: created_at,
        updated_at: updated_at
      }
    end

    @spec to_json!(t()) :: Igor.Json.json()
    def to_json!(args) do
      %{
        id: id,
        code: code,
        name: name,
        uri: uri,
        username: username,
        password: password,
        rev: rev,
        created_at: created_at,
        updated_at: updated_at
      } = args
      %{
        "id" => Igor.Json.pack_value(id, :long),
        "code" => Igor.Json.pack_value(code, :string),
        "name" => Igor.Json.pack_value(name, :string),
        "uri" => Igor.Json.pack_value(uri, :string),
        "username" => Igor.Json.pack_value(username, :string),
        "password" => Igor.Json.pack_value(password, :string),
        "rev" => Igor.Json.pack_value(rev, :int),
        "created_at" => Util.DateTime.to_json!(created_at),
        "updated_at" => Util.DateTime.to_json!(updated_at)
      }
    end

  end

  defmodule CreateClickhouseInstanceRequest do

    @enforce_keys [:code, :name, :uri, :username, :password]
    defstruct [code: nil, name: nil, uri: nil, username: nil, password: nil]

    @type t :: %CreateClickhouseInstanceRequest{code: String.t(), name: String.t(), uri: String.t(), username: String.t(), password: String.t()}

    @spec from_json!(Igor.Json.json()) :: t()
    def from_json!(json) do
      code = Igor.Json.parse_field!(json, "code", :string)
      name = Igor.Json.parse_field!(json, "name", :string)
      uri = Igor.Json.parse_field!(json, "uri", :string)
      username = Igor.Json.parse_field!(json, "username", :string)
      password = Igor.Json.parse_field!(json, "password", :string)
      %CreateClickhouseInstanceRequest{
        code: code,
        name: name,
        uri: uri,
        username: username,
        password: password
      }
    end

    @spec to_json!(t()) :: Igor.Json.json()
    def to_json!(args) do
      %{
        code: code,
        name: name,
        uri: uri,
        username: username,
        password: password
      } = args
      %{
        "code" => Igor.Json.pack_value(code, :string),
        "name" => Igor.Json.pack_value(name, :string),
        "uri" => Igor.Json.pack_value(uri, :string),
        "username" => Igor.Json.pack_value(username, :string),
        "password" => Igor.Json.pack_value(password, :string)
      }
    end

  end

  defmodule UpdateClickhouseInstanceRequest do

    @type t :: %{optional(:code) => String.t(), optional(:name) => String.t(), optional(:uri) => String.t(), optional(:username) => String.t(), optional(:password) => String.t()}

    @spec from_json!(Igor.Json.json()) :: t()
    def from_json!(json) do
      %{}
        |> field_from_json(json, "code", :string, :code)
        |> field_from_json(json, "name", :string, :name)
        |> field_from_json(json, "uri", :string, :uri)
        |> field_from_json(json, "username", :string, :username)
        |> field_from_json(json, "password", :string, :password)
    end

    defp field_from_json(map, json, json_key, type, map_key) do
      case Map.fetch(json, json_key) do
        {:ok, value} -> Map.put(map, map_key, Igor.Json.parse_value!(value, type))
        :error -> map
      end
    end

    @spec to_json!(t()) :: Igor.Json.json()
    def to_json!(args) do
      %{}
        |> field_to_json(args, :code, :string, "code")
        |> field_to_json(args, :name, :string, "name")
        |> field_to_json(args, :uri, :string, "uri")
        |> field_to_json(args, :username, :string, "username")
        |> field_to_json(args, :password, :string, "password")
    end

    defp field_to_json(json, map, map_key, type, json_key) do
      case Map.fetch(map, map_key) do
        {:ok, value} -> Map.put(json, json_key, Igor.Json.pack_value(value, type))
        :error -> json
      end
    end

  end

  defmodule ClickhouseInstanceError do

    @type t ::
      :invalid_code #
    | :invalid_name #
    | :invalid_uri #
    | :invalid_username #
    | :invalid_password #
    | :code_already_exists #
    | :name_already_exists #

    defguard is_clickhouse_instance_error(value) when value === :invalid_code or value === :invalid_name or value === :invalid_uri or value === :invalid_username or value === :invalid_password or value === :code_already_exists or value === :name_already_exists

    @spec from_string!(String.t()) :: t()
    def from_string!("invalid_code"), do: :invalid_code
    def from_string!("invalid_name"), do: :invalid_name
    def from_string!("invalid_uri"), do: :invalid_uri
    def from_string!("invalid_username"), do: :invalid_username
    def from_string!("invalid_password"), do: :invalid_password
    def from_string!("code_already_exists"), do: :code_already_exists
    def from_string!("name_already_exists"), do: :name_already_exists

    @spec to_string!(t()) :: String.t()
    def to_string!(:invalid_code), do: "invalid_code"
    def to_string!(:invalid_name), do: "invalid_name"
    def to_string!(:invalid_uri), do: "invalid_uri"
    def to_string!(:invalid_username), do: "invalid_username"
    def to_string!(:invalid_password), do: "invalid_password"
    def to_string!(:code_already_exists), do: "code_already_exists"
    def to_string!(:name_already_exists), do: "name_already_exists"

    @spec from_json!(String.t()) :: t()
    def from_json!("invalid_code"), do: :invalid_code
    def from_json!("invalid_name"), do: :invalid_name
    def from_json!("invalid_uri"), do: :invalid_uri
    def from_json!("invalid_username"), do: :invalid_username
    def from_json!("invalid_password"), do: :invalid_password
    def from_json!("code_already_exists"), do: :code_already_exists
    def from_json!("name_already_exists"), do: :name_already_exists

    @spec to_json!(t()) :: String.t()
    def to_json!(:invalid_code), do: "invalid_code"
    def to_json!(:invalid_name), do: "invalid_name"
    def to_json!(:invalid_uri), do: "invalid_uri"
    def to_json!(:invalid_username), do: "invalid_username"
    def to_json!(:invalid_password), do: "invalid_password"
    def to_json!(:code_already_exists), do: "code_already_exists"
    def to_json!(:name_already_exists), do: "name_already_exists"

  end

  defmodule Project do

    @moduledoc """
    Projects
    """
    @enforce_keys [:id, :code, :name, :clickhouse_instance_id, :clickhouse_code, :clickhouse_name, :clickhouse_db, :key_su, :key_rw, :rev, :event_validation, :preserve_db_columns, :backup_mode, :created_at, :updated_at]
    defstruct [id: nil, code: nil, name: nil, clickhouse_instance_id: nil, clickhouse_code: nil, clickhouse_name: nil, clickhouse_db: nil, key_su: nil, key_rw: nil, description: nil, schema: "{}", rev: nil, event_validation: nil, preserve_db_columns: nil, backup_mode: nil, created_at: nil, updated_at: nil]

    @type t :: %Project{id: integer, code: String.t(), name: String.t(), clickhouse_instance_id: integer, clickhouse_code: String.t(), clickhouse_name: String.t(), clickhouse_db: String.t(), key_su: String.t(), key_rw: String.t(), description: String.t() | nil, schema: TypesProtocol.project_schema(), rev: non_neg_integer, event_validation: boolean, preserve_db_columns: boolean, backup_mode: boolean, created_at: DateTime.t(), updated_at: DateTime.t()}

    @spec from_json!(Igor.Json.json()) :: t()
    def from_json!(json) do
      id = Igor.Json.parse_field!(json, "id", :long)
      code = Igor.Json.parse_field!(json, "code", :string)
      name = Igor.Json.parse_field!(json, "name", :string)
      clickhouse_instance_id = Igor.Json.parse_field!(json, "clickhouse_instance_id", :long)
      clickhouse_code = Igor.Json.parse_field!(json, "clickhouse_code", :string)
      clickhouse_name = Igor.Json.parse_field!(json, "clickhouse_name", :string)
      clickhouse_db = Igor.Json.parse_field!(json, "clickhouse_db", :string)
      key_su = Igor.Json.parse_field!(json, "key_su", :string)
      key_rw = Igor.Json.parse_field!(json, "key_rw", :string)
      description = Igor.Json.parse_field!(json, "description", :string, nil)
      schema = Igor.Json.parse_field!(json, "schema", :string, "{}")
      rev = Igor.Json.parse_field!(json, "rev", :uint)
      event_validation = Igor.Json.parse_field!(json, "event_validation", :boolean)
      preserve_db_columns = Igor.Json.parse_field!(json, "preserve_db_columns", :boolean)
      backup_mode = Igor.Json.parse_field!(json, "backup_mode", :boolean)
      created_at = Igor.Json.parse_field!(json, "created_at", {:custom, Util.DateTime})
      updated_at = Igor.Json.parse_field!(json, "updated_at", {:custom, Util.DateTime})
      %Project{
        id: id,
        code: code,
        name: name,
        clickhouse_instance_id: clickhouse_instance_id,
        clickhouse_code: clickhouse_code,
        clickhouse_name: clickhouse_name,
        clickhouse_db: clickhouse_db,
        key_su: key_su,
        key_rw: key_rw,
        description: description,
        schema: schema,
        rev: rev,
        event_validation: event_validation,
        preserve_db_columns: preserve_db_columns,
        backup_mode: backup_mode,
        created_at: created_at,
        updated_at: updated_at
      }
    end

    @spec to_json!(t()) :: Igor.Json.json()
    def to_json!(args) do
      %{
        id: id,
        code: code,
        name: name,
        clickhouse_instance_id: clickhouse_instance_id,
        clickhouse_code: clickhouse_code,
        clickhouse_name: clickhouse_name,
        clickhouse_db: clickhouse_db,
        key_su: key_su,
        key_rw: key_rw,
        description: description,
        schema: schema,
        rev: rev,
        event_validation: event_validation,
        preserve_db_columns: preserve_db_columns,
        backup_mode: backup_mode,
        created_at: created_at,
        updated_at: updated_at
      } = args
      %{}
        |> Igor.Json.pack_field("id", id, :long)
        |> Igor.Json.pack_field("code", code, :string)
        |> Igor.Json.pack_field("name", name, :string)
        |> Igor.Json.pack_field("clickhouse_instance_id", clickhouse_instance_id, :long)
        |> Igor.Json.pack_field("clickhouse_code", clickhouse_code, :string)
        |> Igor.Json.pack_field("clickhouse_name", clickhouse_name, :string)
        |> Igor.Json.pack_field("clickhouse_db", clickhouse_db, :string)
        |> Igor.Json.pack_field("key_su", key_su, :string)
        |> Igor.Json.pack_field("key_rw", key_rw, :string)
        |> Igor.Json.pack_field("description", description, :string)
        |> Igor.Json.pack_field("schema", schema, :string)
        |> Igor.Json.pack_field("rev", rev, :uint)
        |> Igor.Json.pack_field("event_validation", event_validation, :boolean)
        |> Igor.Json.pack_field("preserve_db_columns", preserve_db_columns, :boolean)
        |> Igor.Json.pack_field("backup_mode", backup_mode, :boolean)
        |> Igor.Json.pack_field("created_at", created_at, {:custom, Util.DateTime})
        |> Igor.Json.pack_field("updated_at", updated_at, {:custom, Util.DateTime})
    end

  end

  defmodule CreateProjectRequest do

    @enforce_keys [:code, :name, :clickhouse_instance_id, :clickhouse_db]
    defstruct [code: nil, name: nil, clickhouse_instance_id: nil, clickhouse_db: nil, description: nil, event_validation: true, preserve_db_columns: false, backup_mode: false]

    @type t :: %CreateProjectRequest{code: String.t(), name: String.t(), clickhouse_instance_id: integer, clickhouse_db: String.t(), description: String.t() | nil, event_validation: boolean, preserve_db_columns: boolean, backup_mode: boolean}

    @spec from_json!(Igor.Json.json()) :: t()
    def from_json!(json) do
      code = Igor.Json.parse_field!(json, "code", :string)
      name = Igor.Json.parse_field!(json, "name", :string)
      clickhouse_instance_id = Igor.Json.parse_field!(json, "clickhouse_instance_id", :long)
      clickhouse_db = Igor.Json.parse_field!(json, "clickhouse_db", :string)
      description = Igor.Json.parse_field!(json, "description", :string, nil)
      event_validation = Igor.Json.parse_field!(json, "event_validation", :boolean, true)
      preserve_db_columns = Igor.Json.parse_field!(json, "preserve_db_columns", :boolean, false)
      backup_mode = Igor.Json.parse_field!(json, "backup_mode", :boolean, false)
      %CreateProjectRequest{
        code: code,
        name: name,
        clickhouse_instance_id: clickhouse_instance_id,
        clickhouse_db: clickhouse_db,
        description: description,
        event_validation: event_validation,
        preserve_db_columns: preserve_db_columns,
        backup_mode: backup_mode
      }
    end

    @spec to_json!(t()) :: Igor.Json.json()
    def to_json!(args) do
      %{
        code: code,
        name: name,
        clickhouse_instance_id: clickhouse_instance_id,
        clickhouse_db: clickhouse_db,
        description: description,
        event_validation: event_validation,
        preserve_db_columns: preserve_db_columns,
        backup_mode: backup_mode
      } = args
      %{}
        |> Igor.Json.pack_field("code", code, :string)
        |> Igor.Json.pack_field("name", name, :string)
        |> Igor.Json.pack_field("clickhouse_instance_id", clickhouse_instance_id, :long)
        |> Igor.Json.pack_field("clickhouse_db", clickhouse_db, :string)
        |> Igor.Json.pack_field("description", description, :string)
        |> Igor.Json.pack_field("event_validation", event_validation, :boolean)
        |> Igor.Json.pack_field("preserve_db_columns", preserve_db_columns, :boolean)
        |> Igor.Json.pack_field("backup_mode", backup_mode, :boolean)
    end

  end

  defmodule UpdateProjectRequest do

    @type t :: %{optional(:code) => String.t(), optional(:name) => String.t(), optional(:clickhouse_instance_id) => integer, optional(:clickhouse_db) => String.t(), optional(:description) => String.t(), optional(:event_validation) => boolean, optional(:preserve_db_columns) => boolean, optional(:backup_mode) => boolean}

    @spec from_json!(Igor.Json.json()) :: t()
    def from_json!(json) do
      %{}
        |> field_from_json(json, "code", :string, :code)
        |> field_from_json(json, "name", :string, :name)
        |> field_from_json(json, "clickhouse_instance_id", :long, :clickhouse_instance_id)
        |> field_from_json(json, "clickhouse_db", :string, :clickhouse_db)
        |> field_from_json(json, "description", :string, :description)
        |> field_from_json(json, "event_validation", :boolean, :event_validation)
        |> field_from_json(json, "preserve_db_columns", :boolean, :preserve_db_columns)
        |> field_from_json(json, "backup_mode", :boolean, :backup_mode)
    end

    defp field_from_json(map, json, json_key, type, map_key) do
      case Map.fetch(json, json_key) do
        {:ok, value} -> Map.put(map, map_key, Igor.Json.parse_value!(value, type))
        :error -> map
      end
    end

    @spec to_json!(t()) :: Igor.Json.json()
    def to_json!(args) do
      %{}
        |> field_to_json(args, :code, :string, "code")
        |> field_to_json(args, :name, :string, "name")
        |> field_to_json(args, :clickhouse_instance_id, :long, "clickhouse_instance_id")
        |> field_to_json(args, :clickhouse_db, :string, "clickhouse_db")
        |> field_to_json(args, :description, :string, "description")
        |> field_to_json(args, :event_validation, :boolean, "event_validation")
        |> field_to_json(args, :preserve_db_columns, :boolean, "preserve_db_columns")
        |> field_to_json(args, :backup_mode, :boolean, "backup_mode")
    end

    defp field_to_json(json, map, map_key, type, json_key) do
      case Map.fetch(map, map_key) do
        {:ok, value} -> Map.put(json, json_key, Igor.Json.pack_value(value, type))
        :error -> json
      end
    end

  end

  defmodule ProjectError do

    @type t ::
      :invalid_code #
    | :invalid_name #
    | :invalid_clickhouse_instance_id #
    | :invalid_clickhouse_db #
    | :invalid_description #
    | :clickhouse_instance_not_exists #
    | :code_already_exists #
    | :name_already_exists #

    defguard is_project_error(value) when value === :invalid_code or value === :invalid_name or value === :invalid_clickhouse_instance_id or value === :invalid_clickhouse_db or value === :invalid_description or value === :clickhouse_instance_not_exists or value === :code_already_exists or value === :name_already_exists

    @spec from_string!(String.t()) :: t()
    def from_string!("invalid_code"), do: :invalid_code
    def from_string!("invalid_name"), do: :invalid_name
    def from_string!("invalid_clickhouse_instance_id"), do: :invalid_clickhouse_instance_id
    def from_string!("invalid_clickhouse_db"), do: :invalid_clickhouse_db
    def from_string!("invalid_description"), do: :invalid_description
    def from_string!("clickhouse_instance_not_exists"), do: :clickhouse_instance_not_exists
    def from_string!("code_already_exists"), do: :code_already_exists
    def from_string!("name_already_exists"), do: :name_already_exists

    @spec to_string!(t()) :: String.t()
    def to_string!(:invalid_code), do: "invalid_code"
    def to_string!(:invalid_name), do: "invalid_name"
    def to_string!(:invalid_clickhouse_instance_id), do: "invalid_clickhouse_instance_id"
    def to_string!(:invalid_clickhouse_db), do: "invalid_clickhouse_db"
    def to_string!(:invalid_description), do: "invalid_description"
    def to_string!(:clickhouse_instance_not_exists), do: "clickhouse_instance_not_exists"
    def to_string!(:code_already_exists), do: "code_already_exists"
    def to_string!(:name_already_exists), do: "name_already_exists"

    @spec from_json!(String.t()) :: t()
    def from_json!("invalid_code"), do: :invalid_code
    def from_json!("invalid_name"), do: :invalid_name
    def from_json!("invalid_clickhouse_instance_id"), do: :invalid_clickhouse_instance_id
    def from_json!("invalid_clickhouse_db"), do: :invalid_clickhouse_db
    def from_json!("invalid_description"), do: :invalid_description
    def from_json!("clickhouse_instance_not_exists"), do: :clickhouse_instance_not_exists
    def from_json!("code_already_exists"), do: :code_already_exists
    def from_json!("name_already_exists"), do: :name_already_exists

    @spec to_json!(t()) :: String.t()
    def to_json!(:invalid_code), do: "invalid_code"
    def to_json!(:invalid_name), do: "invalid_name"
    def to_json!(:invalid_clickhouse_instance_id), do: "invalid_clickhouse_instance_id"
    def to_json!(:invalid_clickhouse_db), do: "invalid_clickhouse_db"
    def to_json!(:invalid_description), do: "invalid_description"
    def to_json!(:clickhouse_instance_not_exists), do: "clickhouse_instance_not_exists"
    def to_json!(:code_already_exists), do: "code_already_exists"
    def to_json!(:name_already_exists), do: "name_already_exists"

  end

  defmodule SchemaMigration do

    @enforce_keys [:id, :project_id, :project_code, :schema, :created_at]
    defstruct [id: nil, project_id: nil, project_code: nil, previous_schema: nil, schema: nil, schema_diff: nil, created_at: nil]

    @type t :: %SchemaMigration{id: integer, project_id: integer, project_code: String.t(), previous_schema: TypesProtocol.project_schema() | nil, schema: TypesProtocol.project_schema(), schema_diff: String.t() | nil, created_at: DateTime.t()}

    @spec from_json!(Igor.Json.json()) :: t()
    def from_json!(json) do
      id = Igor.Json.parse_field!(json, "id", :long)
      project_id = Igor.Json.parse_field!(json, "project_id", :long)
      project_code = Igor.Json.parse_field!(json, "project_code", :string)
      previous_schema = Igor.Json.parse_field!(json, "previous_schema", :string, nil)
      schema = Igor.Json.parse_field!(json, "schema", :string)
      schema_diff = Igor.Json.parse_field!(json, "schema_diff", :string, nil)
      created_at = Igor.Json.parse_field!(json, "created_at", {:custom, Util.DateTime})
      %SchemaMigration{
        id: id,
        project_id: project_id,
        project_code: project_code,
        previous_schema: previous_schema,
        schema: schema,
        schema_diff: schema_diff,
        created_at: created_at
      }
    end

    @spec to_json!(t()) :: Igor.Json.json()
    def to_json!(args) do
      %{
        id: id,
        project_id: project_id,
        project_code: project_code,
        previous_schema: previous_schema,
        schema: schema,
        schema_diff: schema_diff,
        created_at: created_at
      } = args
      %{}
        |> Igor.Json.pack_field("id", id, :long)
        |> Igor.Json.pack_field("project_id", project_id, :long)
        |> Igor.Json.pack_field("project_code", project_code, :string)
        |> Igor.Json.pack_field("previous_schema", previous_schema, :string)
        |> Igor.Json.pack_field("schema", schema, :string)
        |> Igor.Json.pack_field("schema_diff", schema_diff, :string)
        |> Igor.Json.pack_field("created_at", created_at, {:custom, Util.DateTime})
    end

  end

  defmodule SchemaMigrationOrderBy do

    @moduledoc """
    Customer related items sort fields
    """

    @type t ::
      :id #
    | :created_at #

    defguard is_schema_migration_order_by(value) when value === :id or value === :created_at

    @spec from_string!(String.t()) :: t()
    def from_string!("id"), do: :id
    def from_string!("created_at"), do: :created_at

    @spec to_string!(t()) :: String.t()
    def to_string!(:id), do: "id"
    def to_string!(:created_at), do: "created_at"

    @spec from_json!(String.t()) :: t()
    def from_json!("id"), do: :id
    def from_json!("created_at"), do: :created_at

    @spec to_json!(t()) :: String.t()
    def to_json!(:id), do: "id"
    def to_json!(:created_at), do: "created_at"

  end

  defmodule BackupFieldsOrderBy do

    @moduledoc """
    Backup columns sort fields
    """

    @type t ::
      :name #
    | :field_name #
    | :migration #

    defguard is_backup_fields_order_by(value) when value === :name or value === :field_name or value === :migration

    @spec from_string!(String.t()) :: t()
    def from_string!("name"), do: :name
    def from_string!("field_name"), do: :field_name
    def from_string!("migration"), do: :migration

    @spec to_string!(t()) :: String.t()
    def to_string!(:name), do: "name"
    def to_string!(:field_name), do: "field_name"
    def to_string!(:migration), do: "migration"

    @spec from_json!(String.t()) :: t()
    def from_json!("name"), do: :name
    def from_json!("field_name"), do: :field_name
    def from_json!("migration"), do: :migration

    @spec to_json!(t()) :: String.t()
    def to_json!(:name), do: "name"
    def to_json!(:field_name), do: "field_name"
    def to_json!(:migration), do: "migration"

  end

end
