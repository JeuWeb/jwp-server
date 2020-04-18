defmodule JwpWeb.PubSubSocket do
  use Phoenix.Socket
  require Logger

  ## Channels
  channel "jwp:*", JwpWeb.MainChannel
  @salt "0OL5K3eGcQw8jHLpXXeTa/sSfCvUzRMdsRzmzz1MbKiuvcrsJcL0tm031hkqGTJU"
  @max_age 2 * 60 * 1000

  def create_token(app_id, channels),
    do: sign_token(%{app_id: app_id, channels: channels})

  def sign_token(data),
    do: Phoenix.Token.sign(JwpWeb.Endpoint, @salt, data)

  def verify_token(token),
    do: Phoenix.Token.verify(JwpWeb.Endpoint, @salt, token, max_age: @max_age)

  # Socket params are passed from the client and can
  # be used to verify and authenticate a user. After
  # verification, you can put default assigns into
  # the socket that will be set for all channels, ie
  #
  #     {:ok, assign(socket, :app_id, verified_app_id)}
  #
  # To deny connection, return `:error`.
  #
  # See `Phoenix.Token` documentation for examples in
  # performing token verification on connect.

  def connect(%{"token" => token}, socket, connect_info) do
    case verify_token(token) do
      {:ok, %{app_id: app_id, channels: channels}} ->
        socket =
          socket
          |> assign(:app_id, app_id)
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
