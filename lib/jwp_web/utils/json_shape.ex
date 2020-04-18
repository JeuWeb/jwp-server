defmodule JwpWeb.Utils.JsonShape do
  @moduledoc """
  Json helpers to send success or error reasons.
  """
  @default_detail nil

  def send_json_ok(conn, data),
    do: Phoenix.Controller.json(conn, wrap_json_ok(data))

  def send_json_ok(conn, status, data) when is_integer(status) or is_atom(status) do
    conn
    |> Plug.Conn.put_status(status)
    |> Phoenix.Controller.json(wrap_json_ok(data))
  end

  def wrap_json_ok(data),
    do: %{status: "ok", data: data}

  def send_json_error(conn, message),
    do: send_json_error(conn, message, @default_detail)

  def send_json_error(conn, status, message) when is_integer(status) or is_atom(status),
    do: send_json_error(conn, status, message, @default_detail)

  def send_json_error(conn, message, detail),
    do: send_json_error(conn, conn.status || 500, message, detail)

  def send_json_error(conn, status, message, detail)
      when is_integer(status) or is_atom(status) do
    json = wrap_json_error(message, detail)
    IO.puts("STATUS: #{inspect(status)}")
    IO.puts("JSON: #{inspect(json |> Jason.encode!())}")

    conn
    |> Plug.Conn.put_status(status)
    |> Phoenix.Controller.json(json)
  end

  def wrap_json_error(message, detail),
    do: %{status: "error", error: to_json_error(message, detail)}

  def to_json_error(error, detail \\ @default_detail)

  def to_json_error({:error, message}, detail),
    do: to_json_error(message, detail)

  def to_json_error(message, nil) when is_binary(message),
    do: %{message: message}

  def to_json_error(message, detail),
    do: %{message: force_json(message), detail: force_json(detail)}

  defp force_json(term) do
    case Jason.encode(term) do
      {:ok, json} -> Jason.Fragment.new(json)
      {:error, _} -> "(raw inspect) #{inspect(term)}"
    end
  end
end
