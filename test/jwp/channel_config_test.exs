defmodule Jwp.PubSub.ChannelConfigTest do
  use ExUnit.Case
  alias Jwp.PubSub.ChannelConfig
  import ChannelConfig, only: [cc: 0, cc: 1]

  test "create from map" do
    assert {:ok, cc()} = ChannelConfig.from_map(%{})

    assert {:ok, cc(presence_track: true)} =
      ChannelConfig.from_map(%{"presence_track" => true})

    assert {:error, {:bad_key, "some_bad_key"}} =
      ChannelConfig.from_map(%{"some_bad_key" => true})

    assert {:error, {:bad_value, {"presence_track", "some_string"}}} =
      ChannelConfig.from_map(%{"presence_track" => "some_string"})
  end
end
