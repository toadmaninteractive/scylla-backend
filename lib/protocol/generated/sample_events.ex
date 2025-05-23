# @author Igor compiler
# @doc Compiler version: igorc 2.1.4
# DO NOT EDIT THIS FILE - it is machine generated

defmodule SampleEvents do

  defmodule EventName do

    @type t ::
      :aa_purchase #
    | :achievement_progress #
    | :add_looter #

    defguard is_event_name(value) when value === :aa_purchase or value === :achievement_progress or value === :add_looter

    @spec from_string!(String.t()) :: t()
    def from_string!("aa_purchase"), do: :aa_purchase
    def from_string!("achievement_progress"), do: :achievement_progress
    def from_string!("add_looter"), do: :add_looter

    @spec to_string!(t()) :: String.t()
    def to_string!(:aa_purchase), do: "aa_purchase"
    def to_string!(:achievement_progress), do: "achievement_progress"
    def to_string!(:add_looter), do: "add_looter"

    @spec from_json!(String.t()) :: t()
    def from_json!("aa_purchase"), do: :aa_purchase
    def from_json!("achievement_progress"), do: :achievement_progress
    def from_json!("add_looter"), do: :add_looter

    @spec to_json!(t()) :: String.t()
    def to_json!(:aa_purchase), do: "aa_purchase"
    def to_json!(:achievement_progress), do: "achievement_progress"
    def to_json!(:add_looter), do: "add_looter"

  end

  defmodule AnalyticsEvent do

    @type t :: SampleEvents.AaPurchase.t() | SampleEvents.AchievementProgress.t() | SampleEvents.AddLooter.t()

    @spec from_json!(Igor.Json.json()) :: t() | no_return
    def from_json!(json) do
      tag = Igor.Json.parse_field!(json, "event_name", {:custom, SampleEvents.EventName})
      case tag do
        :aa_purchase -> SampleEvents.AaPurchase.from_json!(json)
        :achievement_progress -> SampleEvents.AchievementProgress.from_json!(json)
        :add_looter -> SampleEvents.AddLooter.from_json!(json)
      end
    end

    @spec to_json!(t()) :: Igor.Json.json() | no_return
    def to_json!(struct) when is_struct(struct, SampleEvents.AaPurchase) do
      SampleEvents.AaPurchase.to_json!(struct)
    end
    def to_json!(struct) when is_struct(struct, SampleEvents.AchievementProgress) do
      SampleEvents.AchievementProgress.to_json!(struct)
    end
    def to_json!(struct) when is_struct(struct, SampleEvents.AddLooter) do
      SampleEvents.AddLooter.to_json!(struct)
    end

  end

  defmodule AaPurchase do

    @enforce_keys [:datetime, :timestamp, :zone, :world, :map, :player_name, :player_sid, :player_guid, :aa_id, :aa_cost, :pre_purchase_points, :post_purchase_points, :total_assigned_points_spent, :total_points_spent]
    defstruct [datetime: nil, timestamp: nil, zone: nil, world: nil, map: nil, player_name: nil, player_sid: nil, player_guid: nil, aa_id: nil, aa_cost: nil, pre_purchase_points: nil, post_purchase_points: nil, total_assigned_points_spent: nil, total_points_spent: nil]

    @type t :: %AaPurchase{datetime: SampleEvents.date_time(), timestamp: non_neg_integer, zone: String.t(), world: atom, map: String.t(), player_name: String.t(), player_sid: integer, player_guid: integer, aa_id: integer, aa_cost: integer, pre_purchase_points: integer, post_purchase_points: integer, total_assigned_points_spent: integer, total_points_spent: integer}

    @spec from_json!(Igor.Json.json()) :: t()
    def from_json!(json) do
      datetime = Igor.Json.parse_field!(json, "datetime", :string)
      timestamp = Igor.Json.parse_field!(json, "timestamp", :ulong)
      zone = Igor.Json.parse_field!(json, "zone", :string)
      world = Igor.Json.parse_field!(json, "world", :atom)
      map = Igor.Json.parse_field!(json, "map", :string)
      player_name = Igor.Json.parse_field!(json, "player_name", :string)
      player_sid = Igor.Json.parse_field!(json, "player_sid", :long)
      player_guid = Igor.Json.parse_field!(json, "player_guid", :long)
      aa_id = Igor.Json.parse_field!(json, "aa_id", :int)
      aa_cost = Igor.Json.parse_field!(json, "aa_cost", :int)
      pre_purchase_points = Igor.Json.parse_field!(json, "pre_purchase_points", :int)
      post_purchase_points = Igor.Json.parse_field!(json, "post_purchase_points", :int)
      total_assigned_points_spent = Igor.Json.parse_field!(json, "total_assigned_points_spent", :int)
      total_points_spent = Igor.Json.parse_field!(json, "total_points_spent", :int)
      %AaPurchase{
        datetime: datetime,
        timestamp: timestamp,
        zone: zone,
        world: world,
        map: map,
        player_name: player_name,
        player_sid: player_sid,
        player_guid: player_guid,
        aa_id: aa_id,
        aa_cost: aa_cost,
        pre_purchase_points: pre_purchase_points,
        post_purchase_points: post_purchase_points,
        total_assigned_points_spent: total_assigned_points_spent,
        total_points_spent: total_points_spent
      }
    end

    @spec to_json!(t()) :: Igor.Json.json()
    def to_json!(args) do
      %{
        datetime: datetime,
        timestamp: timestamp,
        zone: zone,
        world: world,
        map: map,
        player_name: player_name,
        player_sid: player_sid,
        player_guid: player_guid,
        aa_id: aa_id,
        aa_cost: aa_cost,
        pre_purchase_points: pre_purchase_points,
        post_purchase_points: post_purchase_points,
        total_assigned_points_spent: total_assigned_points_spent,
        total_points_spent: total_points_spent
      } = args
      %{
        "datetime" => Igor.Json.pack_value(datetime, :string),
        "timestamp" => Igor.Json.pack_value(timestamp, :ulong),
        "zone" => Igor.Json.pack_value(zone, :string),
        "world" => Igor.Json.pack_value(world, :atom),
        "map" => Igor.Json.pack_value(map, :string),
        "event_name" => SampleEvents.EventName.to_json!(:aa_purchase),
        "player_name" => Igor.Json.pack_value(player_name, :string),
        "player_sid" => Igor.Json.pack_value(player_sid, :long),
        "player_guid" => Igor.Json.pack_value(player_guid, :long),
        "aa_id" => Igor.Json.pack_value(aa_id, :int),
        "aa_cost" => Igor.Json.pack_value(aa_cost, :int),
        "pre_purchase_points" => Igor.Json.pack_value(pre_purchase_points, :int),
        "post_purchase_points" => Igor.Json.pack_value(post_purchase_points, :int),
        "total_assigned_points_spent" => Igor.Json.pack_value(total_assigned_points_spent, :int),
        "total_points_spent" => Igor.Json.pack_value(total_points_spent, :int)
      }
    end

  end

  defmodule AchievementProgress do

    @enforce_keys [:datetime, :timestamp, :zone, :world, :map, :player_name, :player_sid, :event_type, :event_object, :achievement_id, :component_id, :requirement_id, :requirement_type, :new_count]
    defstruct [datetime: nil, timestamp: nil, zone: nil, world: nil, map: nil, player_name: nil, player_sid: nil, event_type: nil, event_object: nil, achievement_id: nil, component_id: nil, requirement_id: nil, requirement_type: nil, new_count: nil]

    @type t :: %AchievementProgress{datetime: SampleEvents.date_time(), timestamp: non_neg_integer, zone: String.t(), world: atom, map: String.t(), player_name: String.t(), player_sid: integer, event_type: atom, event_object: String.t(), achievement_id: integer, component_id: integer, requirement_id: integer, requirement_type: integer, new_count: integer}

    @spec from_json!(Igor.Json.json()) :: t()
    def from_json!(json) do
      datetime = Igor.Json.parse_field!(json, "datetime", :string)
      timestamp = Igor.Json.parse_field!(json, "timestamp", :ulong)
      zone = Igor.Json.parse_field!(json, "zone", :string)
      world = Igor.Json.parse_field!(json, "world", :atom)
      map = Igor.Json.parse_field!(json, "map", :string)
      player_name = Igor.Json.parse_field!(json, "player_name", :string)
      player_sid = Igor.Json.parse_field!(json, "player_sid", :long)
      event_type = Igor.Json.parse_field!(json, "event_type", :atom)
      event_object = Igor.Json.parse_field!(json, "event_object", :string)
      achievement_id = Igor.Json.parse_field!(json, "achievement_id", :long)
      component_id = Igor.Json.parse_field!(json, "component_id", :long)
      requirement_id = Igor.Json.parse_field!(json, "requirement_id", :long)
      requirement_type = Igor.Json.parse_field!(json, "requirement_type", :int)
      new_count = Igor.Json.parse_field!(json, "new_count", :long)
      %AchievementProgress{
        datetime: datetime,
        timestamp: timestamp,
        zone: zone,
        world: world,
        map: map,
        player_name: player_name,
        player_sid: player_sid,
        event_type: event_type,
        event_object: event_object,
        achievement_id: achievement_id,
        component_id: component_id,
        requirement_id: requirement_id,
        requirement_type: requirement_type,
        new_count: new_count
      }
    end

    @spec to_json!(t()) :: Igor.Json.json()
    def to_json!(args) do
      %{
        datetime: datetime,
        timestamp: timestamp,
        zone: zone,
        world: world,
        map: map,
        player_name: player_name,
        player_sid: player_sid,
        event_type: event_type,
        event_object: event_object,
        achievement_id: achievement_id,
        component_id: component_id,
        requirement_id: requirement_id,
        requirement_type: requirement_type,
        new_count: new_count
      } = args
      %{
        "datetime" => Igor.Json.pack_value(datetime, :string),
        "timestamp" => Igor.Json.pack_value(timestamp, :ulong),
        "zone" => Igor.Json.pack_value(zone, :string),
        "world" => Igor.Json.pack_value(world, :atom),
        "map" => Igor.Json.pack_value(map, :string),
        "event_name" => SampleEvents.EventName.to_json!(:achievement_progress),
        "player_name" => Igor.Json.pack_value(player_name, :string),
        "player_sid" => Igor.Json.pack_value(player_sid, :long),
        "event_type" => Igor.Json.pack_value(event_type, :atom),
        "event_object" => Igor.Json.pack_value(event_object, :string),
        "achievement_id" => Igor.Json.pack_value(achievement_id, :long),
        "component_id" => Igor.Json.pack_value(component_id, :long),
        "requirement_id" => Igor.Json.pack_value(requirement_id, :long),
        "requirement_type" => Igor.Json.pack_value(requirement_type, :int),
        "new_count" => Igor.Json.pack_value(new_count, :long)
      }
    end

  end

  defmodule AddLooter do

    @enforce_keys [:datetime, :timestamp, :zone, :world, :map, :player_name, :player_sid, :player_type, :loot_name, :loot_distance, :is_new_loot_system, :is_looter_lost_access, :is_looter_dead, :is_looter_out_of_range]
    defstruct [datetime: nil, timestamp: nil, zone: nil, world: nil, map: nil, player_name: nil, player_sid: nil, player_type: nil, loot_name: nil, loot_distance: nil, is_new_loot_system: nil, is_looter_lost_access: nil, is_looter_dead: nil, is_looter_out_of_range: nil]

    @type t :: %AddLooter{datetime: SampleEvents.date_time(), timestamp: non_neg_integer, zone: String.t(), world: atom, map: String.t(), player_name: String.t(), player_sid: integer, player_type: atom, loot_name: String.t(), loot_distance: float, is_new_loot_system: boolean, is_looter_lost_access: boolean, is_looter_dead: boolean, is_looter_out_of_range: boolean}

    @spec from_json!(Igor.Json.json()) :: t()
    def from_json!(json) do
      datetime = Igor.Json.parse_field!(json, "datetime", :string)
      timestamp = Igor.Json.parse_field!(json, "timestamp", :ulong)
      zone = Igor.Json.parse_field!(json, "zone", :string)
      world = Igor.Json.parse_field!(json, "world", :atom)
      map = Igor.Json.parse_field!(json, "map", :string)
      player_name = Igor.Json.parse_field!(json, "player_name", :string)
      player_sid = Igor.Json.parse_field!(json, "player_sid", :long)
      player_type = Igor.Json.parse_field!(json, "player_type", :atom)
      loot_name = Igor.Json.parse_field!(json, "loot_name", :string)
      loot_distance = Igor.Json.parse_field!(json, "loot_distance", :double)
      is_new_loot_system = Igor.Json.parse_field!(json, "is_new_loot_system", :boolean)
      is_looter_lost_access = Igor.Json.parse_field!(json, "is_looter_lost_access", :boolean)
      is_looter_dead = Igor.Json.parse_field!(json, "is_looter_dead", :boolean)
      is_looter_out_of_range = Igor.Json.parse_field!(json, "is_looter_out_of_range", :boolean)
      %AddLooter{
        datetime: datetime,
        timestamp: timestamp,
        zone: zone,
        world: world,
        map: map,
        player_name: player_name,
        player_sid: player_sid,
        player_type: player_type,
        loot_name: loot_name,
        loot_distance: loot_distance,
        is_new_loot_system: is_new_loot_system,
        is_looter_lost_access: is_looter_lost_access,
        is_looter_dead: is_looter_dead,
        is_looter_out_of_range: is_looter_out_of_range
      }
    end

    @spec to_json!(t()) :: Igor.Json.json()
    def to_json!(args) do
      %{
        datetime: datetime,
        timestamp: timestamp,
        zone: zone,
        world: world,
        map: map,
        player_name: player_name,
        player_sid: player_sid,
        player_type: player_type,
        loot_name: loot_name,
        loot_distance: loot_distance,
        is_new_loot_system: is_new_loot_system,
        is_looter_lost_access: is_looter_lost_access,
        is_looter_dead: is_looter_dead,
        is_looter_out_of_range: is_looter_out_of_range
      } = args
      %{
        "datetime" => Igor.Json.pack_value(datetime, :string),
        "timestamp" => Igor.Json.pack_value(timestamp, :ulong),
        "zone" => Igor.Json.pack_value(zone, :string),
        "world" => Igor.Json.pack_value(world, :atom),
        "map" => Igor.Json.pack_value(map, :string),
        "event_name" => SampleEvents.EventName.to_json!(:add_looter),
        "player_name" => Igor.Json.pack_value(player_name, :string),
        "player_sid" => Igor.Json.pack_value(player_sid, :long),
        "player_type" => Igor.Json.pack_value(player_type, :atom),
        "loot_name" => Igor.Json.pack_value(loot_name, :string),
        "loot_distance" => Igor.Json.pack_value(loot_distance, :double),
        "is_new_loot_system" => Igor.Json.pack_value(is_new_loot_system, :boolean),
        "is_looter_lost_access" => Igor.Json.pack_value(is_looter_lost_access, :boolean),
        "is_looter_dead" => Igor.Json.pack_value(is_looter_dead, :boolean),
        "is_looter_out_of_range" => Igor.Json.pack_value(is_looter_out_of_range, :boolean)
      }
    end

  end

  @type date_time :: String.t()

end
