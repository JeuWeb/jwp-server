defmodule JwpWeb.MainChannelChannelTest do
  use ExUnit.Case
  import Phoenix.ChannelTest


  @endpoint JwpWeb.Endpoint


  setup_all do
    Jwp.Repo.insert(%Jwp.Apps.App{
      id: "seelies-dev",
      email: "admin@seeli.es",
      password: "seelies_123",
      api_key: "some-api-key"
    }, [])
    :ok
  end


  test "connect to a channel" do
    authorization = Base.encode64("seelies-dev:some-api-key")
    payload = Jason.encode!(%{channels: ["some-channel"]})
    {:ok, response} = Mojito.post("http://localhost:4002/api/v1/token/authorize-socket", [{"authorization", "Basic #{authorization}"}, {"content-type", "application/json"}], payload)
    connect_token = Jason.decode!(response.body)["data"]["connect_token"]
    {:ok, socket} = connect(JwpWeb.PubSubSocket, %{"connect_token" => connect_token})
    {:error, _error} = subscribe_and_join(socket, "jwp:seelies-dev:some-unauthorized-channel", %{})
    {:ok, _reply, _socket} = subscribe_and_join(socket, "jwp:seelies-dev:some-channel")
  end
end
