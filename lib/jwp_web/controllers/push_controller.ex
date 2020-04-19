defmodule JwpWeb.PushController do
  use JwpWeb, :controller
  require Logger
  import Jwp.History, only: [register_message: 3]

  def push_message(conn, %{"channel" => channel, "event" => event, "payload" => payload}) do
    %{id: app_id} = Pow.Plug.current_user(conn)

    channel = "jwp:#{app_id}:#{channel}"

    with {:ok, {^event, payload2}} <- register_message(channel, event, payload),
         :ok <- JwpWeb.Endpoint.broadcast!(channel, event, payload2) do
      send_json_ok(conn, 201, %{})
    else
      err ->
        Logger.error(inspect(err))
        send_json_error(conn, 500, "Server error")
    end
  end

  def push_message(conn, _) do
    send_json_error(conn, 400, "Missing data")
  end
end
