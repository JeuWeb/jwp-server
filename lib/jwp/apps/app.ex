defmodule Jwp.Apps.App do
  defstruct id: nil,
            email: nil,
            api_key: nil,
            secret: nil,
            password: nil,
            password_hash: nil,
            webhooks_endpoint: nil,
            webhooks_key: nil

  def pow_user_id_field, do: :id

  def changeset(app, attrs) do
    app
    |> Map.merge(attrs)
    |> maybe_hash_password()
  end

  def maybe_hash_password(app = %{password: nil}), do: app

  def maybe_hash_password(app = %{password: password}) do
    app
    |> Map.put(:password_hash, hash_password(password))
    |> Map.delete(:password)
  end

  def hash_password(password), do: :crypto.hash(:sha256, password)

  def verify_password(%__MODULE__{password_hash: nil}, _), do: false
  def verify_password(_, nil), do: false

  def verify_password(%__MODULE__{password_hash: hashed}, password),
    do: hash_password(password) == hashed
end
