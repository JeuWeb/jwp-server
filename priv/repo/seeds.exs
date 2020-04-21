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
  id: "dev",
  email: "dev@dev.dev",
  password: "$dev2020",
  api_key: "meXxp1xABjiy5skBF9ecnwDBePPqMeIL80hBgHaiHT54yroKKyVZFffb459jLFyi",
  secret: "9rpajQOrCCdZrVY80uOtU",
  webhooks_endpoint: nil
})
