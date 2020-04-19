defmodule Jwp.ApiTest do
  use ExUnit.Case


  setup_all do
    Jwp.Repo.insert(%Jwp.Apps.App{
      id: "seelies-dev",
      email: "admin@seeli.es",
      password: "seelies_123",
      api_key: "some-api-key"
    }, [])
    :ok
  end


  test "ask for a token with no authorization header" do
    {:ok, response} = Mojito.post("http://localhost:4002/api/v1/token/authorize-socket")
    json = Jason.decode!(response.body)

    assert json["status"] == "error"
    assert json["error"]["code"] == 401
    assert json["error"]["message"]
  end


  test "ask for a token with wrong authorization header" do
    {:ok, response} = Mojito.post("http://localhost:4002/api/v1/token/authorize-socket", [{"authorization", "endive"}])
    json = Jason.decode!(response.body)

    assert json["status"] == "error"
    assert json["error"]["code"] == 401
    assert json["error"]["message"]
  end


  test "ask for a token with unexisting account" do
    authorization = Base.encode64("foo:bar")
    {:ok, response} = Mojito.post("http://localhost:4002/api/v1/token/authorize-socket", [{"authorization", "Basic #{authorization}"}])
    json = Jason.decode!(response.body)

    assert json["status"] == "error"
    assert json["error"]["code"] == 401
    assert json["error"]["message"]
  end


  test "ask for a proper token" do
    authorization = Base.encode64("seelies-dev:some-api-key")
    {:ok, response} = Mojito.post("http://localhost:4002/api/v1/token/authorize-socket", [{"authorization", "Basic #{authorization}"}])
    json = Jason.decode!(response.body)

    assert json["status"] == "ok"
    assert json["data"]["app_id"] == "seelies-dev"
    assert json["data"]["connect_token"]
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
    {:ok, response} = Mojito.post("http://localhost:4002/api/v1/push", [{"authorization", "Basic #{authorization}"}])
    json = Jason.decode!(response.body)

    assert json["status"] == "error"
    assert json["error"]["code"] == 400
    assert json["error"]["message"]
  end


  test "push to a channel with authorization header" do
    authorization = Base.encode64("seelies-dev:some-api-key")
    payload = Jason.encode!(%{channel: "foo", event: "bar", payload: %{foo: "bar"}})
    {:ok, response} = Mojito.post("http://localhost:4002/api/v1/push", [{"authorization", "Basic #{authorization}"}, {"content-type", "application/json"}], payload)
    json = Jason.decode!(response.body)

    assert json["status"] == "ok"
  end
end
