# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config



# Configures the endpoint
config :jwp, JwpWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "7MMyu85GNk6l+IupirOS3qk99MUkfMzwVVEppjxuJGCv1gEvSOersTwMqElXOxi7",
  render_errors: [view: JwpWeb.ErrorView, accepts: ~w(json)],
  pubsub_server: Jwp.PubSub,
  live_view: [signing_salt: "kkubeq7y"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id],
  handle_otp_reports: true,
  handle_sasl_reports: true

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :jwp, :pow, users_context: Jwp.Apps

config :jwp, Jwp.Repo,
  data_dir: Path.join(File.cwd!(), "var/db-#{Mix.env()}"),
  name: Jwp.Repo,
  auto_compact: Mix.env != :prod

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
