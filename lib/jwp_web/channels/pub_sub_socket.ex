defmodule JwpWeb.PubSubSocket do
  use Phoenix.Socket, log: :debug
  require Logger
  alias Pow.Ecto.Schema.Password.Pbkdf2

  ## Channels
  channel "jwp:*", JwpWeb.MainChannel
  @salt "0OL5K3eGcQw8jHLpXXeTa/sSfCvUzRMdsRzmzz1MbKiuvcrsJcL0tm031hkqGTJU"
  @max_age 3600

  @todo "verify app_id / api_key"

  def connect(%{"app_id" => claim_app_id,"auth" => token} = params , socket, connect_info) do
    case verify_token(claim_app_id, token) do
      {:ok, socket_id} ->
        socket =
          socket
          |> assign(:app_id, claim_app_id)
          |> assign(:socket_id, socket_id)

        {:ok, socket}
      {:error, reason} ->
        Logger.error(inspect(reason))
        :error
    end
  end
  
  # We receive a token like this: "5e9f49be04150:1587499313:1827D01F4EDA2EF16E752FA13A98AC1691256A751C34FCC1423DD7865E353B35"
  # which is <socket_id>:<expiration_time>:<signature>.
  # The signature is the HMAC of <socket_id>:<expiration_time> with
  # the secret key of app_id.
  defp verify_token(claim_app_id, token) do
    with {:ok, socket_id, expiration_time, signature} <- split_token(token),
         :ok <- validate_expiration_time(expiration_time),
         {:ok, %{secret: secret}} <- fetch_app(claim_app_id) do
            auth_string = "#{socket_id}:#{expiration_time}"
            expected = digest(secret, auth_string)
            case compare_hash(expected, signature) do
              true -> {:ok, socket_id}
              #@todo do not log good signatures
              false -> {:error, {:bad_signature, signature, expected}}
            end           
         end
  end

  defp split_token(token) do
    case String.split(token, ":", parts: 3) do
      [a, b, c] -> {:ok, a, b, c}
      _ -> {:error, :bad_token}
    end
  end
  
  defp fetch_app(app_id) do
    case Jwp.Repo.fetch(Jwp.Apps.App, app_id) do
      :error -> {:error, {:app_not_found, app_id}}
      found -> found
    end
  end

  defp digest(secret, data),
    do: :crypto.hmac(:sha256, secret, data) |> Base.encode16

  defp compare_hash(a, b),
    do: Pbkdf2.compare(a, b)

  defp validate_expiration_time(time) when is_binary(time) do
    case Integer.parse(time) do
      {t, ""} -> validate_expiration_time(t)
      _ -> {:error, {:bad_expiration, time}}
    end
  end

  defp validate_expiration_time(time) when is_integer(time) do
    now = :os.system_time(:seconds)
    if time > now do
      :ok
    else
      {:error, :expired}
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
