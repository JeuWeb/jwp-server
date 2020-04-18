defmodule Jwp.ChannelConfigTest do
  use ExUnit.Case
  import Jwp.ChannelConfig

  test "create from map" do
    assert {:ok, cc()} = Jwp.ChannelConfig.from_map(%{})

    assert {:ok, cc(presence_track: true)} =
             Jwp.ChannelConfig.from_map(%{"presence_track" => true})

    assert {:error, {:bad_key, "some_bad_key"}} =
             Jwp.ChannelConfig.from_map(%{"some_bad_key" => true})

    assert {:error, {:bad_value, {"presence_track", "some_string"}}} =
             Jwp.ChannelConfig.from_map(%{"presence_track" => "some_string"})
  end
end
