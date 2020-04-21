defmodule JwpWeb.MainChannelTest do
  use ExUnit.Case
  import Phoenix.ChannelTest
  alias JwpWeb.PubSubSocket
  alias JwpWeb.MainChannel

  @endpoint JwpWeb.Endpoint
  @app_id "crypto-app-id"
  @app_secret "crypto-secret"
  @socket_id "1234"
  @short_topic "tests"
  @channel "jwp:#{@app_id}:#{@short_topic}"

  setup_all do
    Jwp.Repo.insert(
      %Jwp.Apps.App{
        id: @app_id,
        email: "hello@cryptodev.com",
        password: nil,
        api_key: nil,
        secret: @app_secret,
        webhooks_endpoint: nil,
        webhooks_key: nil
      })
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

  test "can connect to a socket" do
    params = socket_params(:expire, :os.system_time(:second) + 10)
    assert {:ok, %Phoenix.Socket{} = socket} = connect(PubSubSocket, params)
    close(socket)
  end

  test "cannot connect with expiration time too high" do
    params = socket_params(:expire, :os.system_time(:second) + 10000000)
    assert :error = connect(PubSubSocket, params)
  end
  
  test "cannot connect with expired token" do
    params = socket_params(:expire, :os.system_time(:second) - 1)
    assert :error = connect(PubSubSocket, params)
  end

  test "connecting to a channel requires appropriate auth" do
    params = %{}
    {:error, %{reason: "unauthorized"}} = socket(PubSubSocket, params, %{hello: :world})
    |> subscribe_and_join(MainChannel, @channel)
  end
  
  test "can connect to a channel" do
    params = socket_params(:expire, :os.system_time(:second) + 10)
    {:ok, socket} = connect(PubSubSocket, params)
    connect_info = "#{@socket_id}:#{@short_topic}"
    auth = digest(connect_info)

    assert {:ok, _, socket} = subscribe_and_join(socket, @channel, %{"auth" => auth})

    ass = socket.assigns
    assert ass.app_id == @app_id
    assert ass.short_topic == @short_topic
    assert ass.socket_id == @socket_id
  end

  @todo "test channel with data"
end
