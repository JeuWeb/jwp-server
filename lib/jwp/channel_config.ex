defmodule Jwp.ChannelConfig do
  require Record

  @ext_keys [
    "presence_track",
    "presence_diffs",
    "webhook_join",
    "webhook_leave"
  ]
  ## Channel config record

  # The record definition contains the default values. Currently, all
  # channel features are disabled.
  Record.defrecord(:cc,
    presence_track: false,
    presence_diffs: false,
    webhook_join: false,
    webhook_leave: false
  )

  def from_map(map) when is_map(map) do
    map
    |> Map.to_list()
    |> IO.inspect(label: "CHANNEL TO KW")
    |> from_kw()
    |> IO.inspect(label: "CHANNEL FROM MAP")
  end

  def from_kw(kw),
    do: from_kw(kw, cc())

  defp from_kw([{"presence_track", val} | kw], acc) when is_boolean(val),
    do: from_kw(kw, cc(acc, presence_track: val))

  defp from_kw([{"presence_diffs", val} | kw], acc) when is_boolean(val),
    do: from_kw(kw, cc(acc, presence_diffs: val))

  defp from_kw([{"webhook_join", val} | kw], acc) when is_boolean(val),
    do: from_kw(kw, cc(acc, webhook_join: val))

  defp from_kw([{"webhook_leave", val} | kw], acc) when is_boolean(val),
    do: from_kw(kw, cc(acc, webhook_leave: val))

  defp from_kw([{key, val} | kw], _) when key in @ext_keys,
    do: {:error, {:bad_value, {key, val}}}

  defp from_kw([{bad_key, _} | kw], _),
    do: {:error, {:bad_key, bad_key}}

  defp from_kw([], acc),
    do: {:ok, acc}

  def expand_error({:bad_key, key}),
    do: %{code: "unknown_channel_config_key", key: key}

  def expand_error({:bad_value, {key, value}}),
    do: %{code: "incorrect_channel_config_value", key: key, value: value}

  def expand_error(other),
    do: other

  def format(
        cc(
          presence_track: pt,
          presence_diffs: pd,
          webhook_join: wj,
          webhook_leave: wl
        )
      ) do
    "#<ChannelConfig presence_track: #{pt}, presence_diffs: #{pd}, webhook_join: #{wj}, webhook_leave: #{
      wl
    }>"
  end
end
