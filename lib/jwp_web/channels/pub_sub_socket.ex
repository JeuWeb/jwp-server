defmodule JwpWeb.PubSubSocket do
  use Phoenix.Socket
  require Logger

  ## Channels
  channel "jwp:*", JwpWeb.MainChannel
  @salt "0OL5K3eGcQw8jHLpXXeTa/sSfCvUzRMdsRzmzz1MbKiuvcrsJcL0tm031hkqGTJU"
  @max_age 2 * 60 * 1000

  def create_token(app_id, socket_id, channels) do
    Phoenix.Token.sign(JwpWeb.Endpoint, @salt, {app_id, socket_id, channels})
  end

  def verify_token(token) do
    Phoenix.Token.verify(JwpWeb.Endpoint, @salt, token, max_age: @max_age)
  end

  def connect(%{"connect_token" => token}, socket, connect_info) do
    case verify_token(token) do
      {:ok, {app_id, socket_id, channels}} ->
        socket =
          socket
          |> assign(:app_id, app_id)
          |> assign(:socket_id, socket_id)
          |> assign(:allowed_channels, channels)

        {:ok, socket}

      {:error, reason} ->
        Logger.error(inspect(reason))
        :error
    end
  end

  def connect(_params, _socket, _connect_info) do
    Logger.error("Token missing")
    :error
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
