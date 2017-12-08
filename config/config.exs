# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :oceanconnect,
  ecto_repos: [Oceanconnect.Repo]

# Configures the endpoint
config :oceanconnect, OceanconnectWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "ci/oy/zlk3YpZpTfBm3CvP+Vw7aQIV1chRpu/ga3rFhoUX8ABlbEYZOWz/UhN9kz",
  render_errors: [view: OceanconnectWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Oceanconnect.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :hound, driver: "selenium"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
