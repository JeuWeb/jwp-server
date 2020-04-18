defmodule JwpWeb.Plug.ApiAuth do
  @moduledoc false
  require Logger
  use Pow.Plug.Base
  alias Plug.Conn
  alias Pow.Config

  def create(conn, user, _) do
    {conn, user}
  end

  def delete(_, _) do
    raise "called delete"
  end

  def fetch(conn, _config) do
    # _config is [mod: JwpWeb.Plug.ApiAuth, plug: JwpWeb.Plug.ApiAuth, otp_app: :jwp]

    with {:ok, token} <- fetch_auth_token(conn),
         {:ok, credentials} <- decode_token(token),
         {:ok, app_params} <- decode_credentials(credentials),
         {:ok, user} <- find_by_api_key(app_params) do
      {conn, user}
    else
      error ->
        Logger.error("Invalid api auth: #{inspect(error)}")
        {conn, nil}
    end
  end

  defp fetch_auth_token(conn) do
    case Conn.get_req_header(conn, "authorization") do
      [token | _rest] -> {:ok, token}
      _any -> :error
    end
  end

  defp decode_token("Basic " <> b64),
    do: Base.decode64(b64)

  defp decode_token(_),
    do: {:error, :invalid_token}

  defp decode_credentials(bin) do
    case String.split(bin, ":") do
      [id, api_key] -> {:ok, %{"id" => id, "api_key" => api_key}}
      _any -> {:error, :invalid_credentials}
    end
  end

  defp find_by_api_key(%{"id" => id, "api_key" => api_key}) do
    case Jwp.Repo.get(Jwp.Apps.App, id) do
      %{api_key: ^api_key, id: ^id} = app -> {:ok, app}
      other -> {:error, {:not_found, {id, api_key, other}}}
    end
  end
end
