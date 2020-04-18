defmodule Jwp.Repo do
  def child_spec([]) do
    conf = Application.fetch_env!(:jwp, __MODULE__)
    CubDB.child_spec(conf)
  end
end
