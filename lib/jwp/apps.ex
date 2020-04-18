defmodule Jwp.Apps do
  # The behaviour is defined in the Pow.Ecto... namespace but does
  # not have to rely on ecto

  use Pow.Ecto.Context,
    repo: Jwp.Apps,
    user: Jwp.Apps.App

  def generate_id,
    do: UUID.uuid4()

  def generate_key(length \\ 32) when length > 31,
    do: :crypto.strong_rand_bytes(length) |> Base.encode64() |> binary_part(0, length)

  def insert(%Jwp.Apps.App{id: id} = app, _) when is_binary(id) do
    :ok = CubDB.put(Jwp.Repo, {Jwp.Apps.App, id}, app)
    {:ok, app}
  end

  def get_by(Jwp.Apps.App, spec, opts) do
    get_by!(Jwp.Apps.App, spec, opts)
  end

  def get_by!(Jwp.Apps.App, [{:id, id}], []) do
    CubDB.get(Jwp.Repo, {Jwp.Apps.App, id})
    |> IO.inspect(label: "FOUND USER #{id} ?")
  end
end
