defmodule Jwp.Apps do
  # The behaviour is defined in the Pow.Ecto... namespace but does
  # not have to rely on ecto
  use Pow.Ecto.Context,
    repo: Jwp.Repo,
    user: Jwp.Apps.App
end
