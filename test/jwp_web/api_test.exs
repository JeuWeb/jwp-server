defmodule Jwp.ApiTest do
  use ExUnit.Case

  setup_all do
    Jwp.Repo.insert(
      %Jwp.Apps.App{
        id: "seelies-dev",
        email: "admin@seeli.es",
        password: "seelies_123",
        api_key: "some-api-key"
      },
      []
    )

    :ok
  end


  test "push to a channel with no authorization header" do
    {:ok, response} = Mojito.post("http://localhost:4002/api/v1/push")
    json = Jason.decode!(response.body)

    assert json["status"] == "error"
    assert json["error"]["code"] == 401
    assert json["error"]["message"]
  end

  test "push to a channel with authorization header but no channel/event/payload" do
    authorization = Base.encode64("seelies-dev:some-api-key")

    {:ok, response} =
      Mojito.post("http://localhost:4002/api/v1/push", [
        {"authorization", "Basic #{authorization}"}
      ])

    json = Jason.decode!(response.body)

    assert json["status"] == "error"
    assert json["error"]["code"] == 400
    assert json["error"]["message"]
  end

  test "push to a channel with authorization header" do
    authorization = Base.encode64("seelies-dev:some-api-key")

    payload =
      Jason.encode!(%{channel: "lobby", event: "new-message", payload: %{message: "Hello world!"}})

    {:ok, response} =
      Mojito.post(
        "http://localhost:4002/api/v1/push",
        [{"authorization", "Basic #{authorization}"}, {"content-type", "application/json"}],
        payload
      )

    json = Jason.decode!(response.body)

    assert json["status"] == "ok"
  end
end
