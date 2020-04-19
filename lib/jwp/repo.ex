defmodule Jwp.Repo do
  @conf Application.fetch_env!(:jwp, __MODULE__)
  @repo Keyword.fetch!(@conf, :name)

  def child_spec([]),
    do: CubDB.child_spec(@conf)

  def generate_key(length \\ 32) when length > 31,
    do: :crypto.strong_rand_bytes(length) |> Base.encode64() |> binary_part(0, length)

  def insert(%mod{id: id} = entity, []) do
    case CubDB.put(@repo, {mod, id}, entity) do
      :ok ->
        {:ok, entity}
        # herror handling ?
    end
  end

  @doc """
  We are providing the same API as Ecto Repos, so the getters return
  an entity or nil. Not an :ok/:error tuple.
  """
  def get(mod, id),
    do: CubDB.get(@repo, {mod, id}, nil)

  def get_by(mod, [{:id, id}], []) do
    get(mod, id)
  end

  def get_by!(mod, spec, [] = opts) do
    case get_by(Jwp.Apps.App, spec, opts) do
      nil -> raise "Could not find #{mod} by #{inspect(spec)}"
      found -> found
    end
  end
end
