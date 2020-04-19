use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :jwp, JwpWeb.Endpoint,
  http: [port: 4002],
  server: true

# Print only warnings and errors during test
config :logger, level: :warn

config :jwp, MyAppWeb.Endpoint, live_view: [signing_salt: "SECRET_SALT"]
