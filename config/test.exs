use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :oceanconnect, OceanconnectWeb.Endpoint,
  http: [port: 4001],
  url: [host: "localhost", port: 80],
  server: true

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :oceanconnect, Oceanconnect.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: System.get_env("DATA_DB_USER") || "postgres",
  password: System.get_env("DATA_DB_PASS") || "postgres",
  hostname: System.get_env("DATA_DB_HOST") || "localhost",
  database: "oceanconnect_test",
  pool: Ecto.Adapters.SQL.Sandbox,
  ownership_timeout: 25_000

config :oceanconnect, :disable_css_transitions, true
config :oceanconnect, :sql_sandbox, true

config :oceanconnect, :task_supervisor, Oceanconnect.FakeTaskSupervisor
config :oceanconnect, :event_storage, Oceanconnect.FakeEventStorage
config :oceanconnect, :store_starter, true

config :hound,
  driver: "chrome_driver"

# browser: "chrome_headless"

config :oceanconnect, OceanconnectWeb.Mailer, adapter: Bamboo.TestAdapter
