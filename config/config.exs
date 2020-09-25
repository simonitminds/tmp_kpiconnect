# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :oceanconnect,
  ecto_repos: [Oceanconnect.Repo]

# guardian config
config :oceanconnect, Oceanconnect.Guardian,
  issuer: "ocm",
  secret_key: "n+2GhSFsoquPltwZ0p6fsE3WAmVzqLtkV5fDsTek8axW3Lcnt072s+S7fEjsUDNV"

# Configures the endpoint
config :oceanconnect, OceanconnectWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "VNn8or6QKekZ6Wg74hL/GvtqU7/8E1dx7ckxT7YWsZ702Y2hCgLoYd5ABtKLHqDY",
  render_errors: [view: OceanconnectWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Oceanconnect.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Configure default email addresses and delay offsets
config :oceanconnect, :emails, %{
  system: "auctions@KPIocean.com",
  admin: "nbol@KPIocean.com",
  auction_starting_soon_offset: 15 * 60 * 1_000,
  delivered_coq_reminder_offset: 24 * 60 * 60 * 1_000
}

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
