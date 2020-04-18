defmodule Jwp.Apps.App do
  defstruct id: nil, email: nil, password: nil, api_key: nil, password_hash: nil

  def pow_user_id_field, do: :id

  def changeset(app, attrs) do
    app
    |> Map.merge(attrs)
    |> maybe_hash_password()
  end

  def maybe_hash_password(app) do
    case app do
      %{password: nil} ->
        app

      %{password: password} ->
        app
        |> Map.put(:password_hash, hash_password(password))
        |> Map.delete(:password)
    end
  end

  defp hash_password(password) do
    "todo-hash." <> password
  end

  def verify_password(a, b) do
    verify_password2(a, b)
    |> IO.inspect(label: "VERIFIED")
  end

  def verify_password2(%__MODULE__{password_hash: nil}, _), do: false
  def verify_password2(_, nil), do: false

  def verify_password2(%__MODULE__{password_hash: hashed}, password),
    do: hash_password(password) == hashed
end
