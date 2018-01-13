use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :oceanconnect, OceanconnectWeb.Endpoint,
  http: [port: 4001],
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
  pool: Ecto.Adapters.SQL.Sandbox


config :oceanconnect, :sql_sandbox, true

config :hound,
  driver: "selenium",
  browser: "chrome",
  host: System.get_env("DATA_CHROME_HOST") || "localhost",
  app_host: System.get_env("HOSTNAME") || "localhost",
  app_port: 4001


