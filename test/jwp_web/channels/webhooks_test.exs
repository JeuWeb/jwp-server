defmodule JwpWeb.WebHooksTest do
  use ExUnit.Case
  import Phoenix.ChannelTest

  @endpoint JwpWeb.Endpoint
  @app_secret "seeeeeelies"
  @app_id "seelies-hook"
  @socket_id "my-user-123"

  setup_all do
    Jwp.Repo.insert(
      %Jwp.Apps.App{
        id: @app_id,
        email: "admin@seeli.es",
        password: "seelies_123",
        secret: @app_secret,
        api_key: "some-api-key",
        webhooks_endpoint: "http://127.0.0.1:4000/webhooks_endpoint",
        webhooks_key: "some-webhooks-key"
      },
      []
    )

    :ok
  end

  defp digest(data) when is_binary(data),
    do: Jwp.Auth.SocketAuth.digest(@app_secret, data)

  defp socket_params(:expire, expire) do
    # A socket connection token is "<socketID>:<endTime>"
    connect_info = "#{@socket_id}:#{expire}"
    token = digest(connect_info)
    _params = %{"app_id" => @app_id, "auth" => "#{connect_info}:#{token}"}
  end


  test "opt-in for joins and leaves notifications" do
    params = socket_params(:expire, :os.system_time(:second) + 60)
    assert {:ok, socket} = connect(JwpWeb.PubSubSocket, params)

    connect_info = "#{@socket_id}:some-channel"
    auth = digest(connect_info)
    assert {:ok, _, socket} = subscribe_and_join(socket, "jwp:#{@app_id}:some-channel", %{"auth" => auth})

    Process.unlink(socket.channel_pid)
    close(socket)
  end
end
