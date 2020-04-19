defmodule JwpWeb.MainPresence do
  use Phoenix.Presence,
    otp_app: :jwp,
    pubsub_server: Jwp.PubSub
end
