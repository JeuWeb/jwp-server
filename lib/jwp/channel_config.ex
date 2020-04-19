defmodule Jwp.ChannelConfig do
  require Record

  @ext_keys [
    "presence_track",
    "presence_diffs",
    "notify_joins",
    "notify_leaves",
    "meta"
  ]
  ## Channel config record

  # The record definition contains the default values. Currently, all
  # channel features are disabled.
  Record.defrecord(:cc,
    presence_track: false,
    presence_diffs: false,
    notify_joins: false,
    notify_leaves: false,
    meta: %{}
  )

  def from_map(map) when is_map(map) do
    map
    |> Map.to_list()
    |> from_kw()
  end

  def from_kw(kw),
    do: from_kw(kw, cc())

  defp from_kw([{"presence_track", val} | kw], acc) when is_boolean(val),
    do: from_kw(kw, cc(acc, presence_track: val))

  defp from_kw([{"presence_diffs", val} | kw], acc) when is_boolean(val),
    do: from_kw(kw, cc(acc, presence_diffs: val))

  defp from_kw([{"notify_joins", val} | kw], acc) when is_boolean(val),
    do: from_kw(kw, cc(acc, notify_joins: val))

  defp from_kw([{"notify_leaves", val} | kw], acc) when is_boolean(val),
    do: from_kw(kw, cc(acc, notify_leaves: val))

  defp from_kw([{"meta", val} | kw], acc) when is_map(val),
    do: from_kw(kw, cc(acc, meta: val))

  defp from_kw([{key, val} | _kw], _) when key in @ext_keys,
    do: {:error, {:bad_value, {key, val}}}

  defp from_kw([{bad_key, _} | _kw], _),
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
          notify_joins: wj,
          notify_leaves: wl,
          meta: m
        )
      ) do
    """
    #ChannelConfig<
      presence_track: #{pt}
      presence_diffs: #{pd}
      notify_joins: #{wj}
      notify_leaves: #{wl}
      meta: #{inspect(m, pretty: true)}
    >
    """
  end
end
