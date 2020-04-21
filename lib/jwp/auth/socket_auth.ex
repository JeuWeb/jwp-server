defmodule Jwp.Auth.SocketAuth do

  @socket_token_max_age_sec 3600

  # We receive a token like this: "5e9f49be04150:1587499313:1827D01F4EDA2EF16E752FA13A98AC1691256A751C34FCC1423DD7865E353B35"
  # which is <socket_id>:<expiration_time>:<signature>.
  # The signature is the HMAC of <socket_id>:<expiration_time> with
  # the secret key of app_id.
  def verify_socket_token(claim_app_id, token) do
    with {:ok, [socket_id, expiration_time, signature]} <- split(token, 3),
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

  def verify_channel_token(claim_app_id, socket_id, short_topic, json_data, signature) do
    case Jwp.Repo.fetch(Jwp.Apps.App, claim_app_id) do
      :error -> {:error, {:app_not_found, claim_app_id}}
      # If ok we will digest the auth string and compare the results
      {:ok, %{secret: secret}} ->
          auth_string = case json_data do
            nil -> "#{socket_id}:#{short_topic}"
            json -> "#{socket_id}:#{short_topic}:#{json}"
          end
          expected = Jwp.Auth.SocketAuth.digest(secret, auth_string)
          case compare_hash(expected, signature) do
            true -> :ok
            #@todo do not log good signatures
            # false -> {:error, {:bad_signature, signature, expected}}
            false -> {:error, :bad_signature}
          end
    end
  end

  def digest(secret, data) when is_binary(secret) and is_binary(data),
    do: :crypto.hmac(:sha256, secret, data) |> Base.encode16

  def split(string, parts) when is_binary(string) and is_integer(parts) do
    case String.split(string, ":", parts: parts) do
      list when length(list) == parts -> {:ok, list}
      _ -> {:error, :malformed_string}
    end
  end

  defp compare_hash(a, b),
    do: Pow.Ecto.Schema.Password.Pbkdf2.compare(a, b)

  defp fetch_app(app_id) do
    case Jwp.Repo.fetch(Jwp.Apps.App, app_id) do
      :error -> {:error, {:app_not_found, app_id}}
      found -> found
    end
  end

  defp validate_expiration_time(time) when is_binary(time) do
    case Integer.parse(time) do
      {t, ""} -> validate_expiration_time(t)
      _ -> {:error, {:bad_expiration, time}}
    end
  end

  defp validate_expiration_time(time) when is_integer(time) do
    now = :os.system_time(:seconds)
    cond do
      time > (now + @socket_token_max_age_sec) -> {:error, :loose_expiration}
      time > now -> :ok
      true -> {:error, :expired}
    end
  end

end