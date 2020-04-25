defmodule JwpWeb.PushController do
  use JwpWeb, :controller
  require Logger

  def push_message(conn, %{"channel" => channel, "event" => event, "payload" => payload}) do
    %{id: app_id} = Pow.Plug.current_user(conn)

    channel = "jwp:#{app_id}:#{channel}"

    case JwpWeb.Endpoint.broadcast!(channel, event, payload) do
      :ok -> 
        send_json_ok(conn, 201, %{})
      err ->
        Logger.error(inspect(err))
        send_json_error(conn, 500, "Server error")
    end
  end

  def push_message(conn, _) do
    send_json_error(conn, 400, "Missing data")
  end
end
