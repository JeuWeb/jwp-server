# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Jwp.Repo.insert!(%Jwp.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

Jwp.Apps.create(%Jwp.Apps.App{
  id: "b4157e65-be69-45df-9b77-3ac2361c53d9",
  email: "dev@dev.dev",
  password: "$dev2020",
  api_key: "meXxp1xABjiy5skBF9ecnwDBePPqMeIL80hBgHaiHT54yroKKyVZFffb459jLFyi"
})
