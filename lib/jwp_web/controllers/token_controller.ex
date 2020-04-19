defmodule JwpWeb.TokenController do
  use JwpWeb, :controller

  def auth_socket(conn, params) do
    %{id: app_id} = Pow.Plug.current_user(conn)

    channels_raw = Map.get(params, "channels", [])
    socket_id_raw = Map.get(params, "socket_id", nil)

    with {:ok, channels} <- normalize_channels_config(channels_raw),
         {:ok, socket_id} <- check_socket_id(socket_id_raw) do
      connect_token = JwpWeb.PubSubSocket.create_token(app_id, socket_id, channels)
      send_json_ok(conn, %{"app_id" => app_id, "connect_token" => connect_token})
    else
      {:error, :bad_socket_id} ->
        send_json_error(conn, 400, "bad_socket_id", socket_id_raw)

      {:error, reason} ->
        send_json_error(conn, 400, "bad_config", Jwp.ChannelConfig.expand_error(reason))
    end
  end

  defp normalize_channels_config(channels) when is_list(channels) do
    channels
    |> Enum.map(&{&1, %{}})
    |> Enum.into(%{})
    |> normalize_channels_config()
  end

  defp normalize_channels_config(channels) when is_map(channels) do
    channels
    |> Enum.reduce({:ok, %{}}, fn
      _, {:error, _} = err ->
        err

      {name, conf}, {:ok, confs} ->
        with {:ok, conf} <- normalize_conf(conf) do
          {:ok, Map.put(confs, name, conf)}
        end
    end)
  end

  defp normalize_channels_config(other),
    do: {:error, {:bad_format, other}}

  # handling PHP client empty objects that can be sent as arrays
  # defp normalize_conf([]),
  #   do: normalize_conf(%{})

  # Long version, but produces very long URLs

  # @defaults %{
  #   presence_track: false,
  #   presence_diffs: false,
  #   notify_joins: false,
  #   notifiy_leaves: false
  # }

  # defp normalize_conf(conf) when is_map(conf) do
  #   {:ok, Map.merge(@defaults, Map.take(conf, Map.keys(@defaults)))}
  # end

  defp normalize_conf(conf) when is_map(conf) do
    Jwp.ChannelConfig.from_map(conf)
  end

  defp normalize_conf(other) do
    {:error, {:bad_config, other}}
  end

  # user id can be nil, the socked will be anonymous
  defp check_socket_id(nil), do: {:ok, nil}
  defp check_socket_id(bin) when is_binary(bin), do: {:ok, bin}
  defp check_socket_id(_other), do: {:error, :bad_socket_id}
end
