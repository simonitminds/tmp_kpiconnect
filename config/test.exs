import Config

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
  username: System.get_env("DATA_DB_USER") || "postgres",
  password: System.get_env("DATA_DB_PASS") || "changeme",
  hostname: System.get_env("DATA_DB_HOST") || "localhost",
  database: "oceanconnect_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  ownership_timeout: 25_000

config :oceanconnect, :disable_css_transitions, true

config :oceanconnect, :sql_sandbox, true

config :oceanconnect, :task_supervisor, Oceanconnect.FakeTaskSupervisor
config :oceanconnect, :exclude_optional_services, true

config :oceanconnect, :file_io, Oceanconnect.FakeIO

config :hound,
  driver: "chrome_driver"

config :bamboo, :refute_timeout, 10

config :oceanconnect, :emails, %{
  system: "system@example.com",
  admin: "admin@example.com",
  auction_starting_soon_offset: 1_000,
  delivered_coq_reminder_offset: 1_000
}

# browser: "chrome_headless"

config :oceanconnect, OceanconnectWeb.Mailer, adapter: Bamboo.TestAdapter
