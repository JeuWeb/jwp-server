defmodule JwpWeb.PubSubSocket do
  use Phoenix.Socket, log: :debug
  require Logger

  ## Channels
  channel "jwp:*", JwpWeb.MainChannel

  def connect(%{"app_id" => claim_app_id, "auth" => token}, socket, _) do
    case Jwp.Auth.SocketAuth.verify_socket_token(claim_app_id, token) do
      {:ok, socket_id} ->
        socket = socket
          |> assign(:app_id, claim_app_id)
          |> assign(:socket_id, socket_id)

        {:ok, socket}
      {:error, reason} ->
        Logger.error(inspect(reason))
        :error
    end
  end
  



  # Socket id's are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "user_socket:#{socket.assigns.app_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     JwpWeb.Endpoint.broadcast("user_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  def id(_socket), do: nil
end
