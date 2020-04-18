defmodule JwpWeb.TokenController do
  use JwpWeb, :controller

  def auth_socket(conn, params) do
    %{id: app_id} = Pow.Plug.current_user(conn)
    params |> IO.inspect(label: "AUTH SOCKET PARAMS")

    channels_config =
      Map.get(params, "channels", [])
      |> IO.inspect(label: "INBOUND CHANNELS CONFIG")
      |> normalize_channels_config()
      |> IO.inspect(label: "NORMALIZED CHANNELS CONFIG")
      |> case do
        {:ok, channels} ->
          connect_token = JwpWeb.PubSubSocket.create_token(app_id, channels)

          send_json_ok(conn, %{"app_id" => app_id, "connect_token" => connect_token})

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
        IO.inspect(name, label: "CONFIGURE")

        with {:ok, conf} <- normalize_conf(conf) do
          {:ok, Map.put(confs, name, conf)}
          |> IO.inspect(label: "LOL")
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
  #   webhook_join: false,
  #   webhook_leave: false
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
end
