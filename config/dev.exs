import Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with brunch.io to recompile .js and .css sources.
config :oceanconnect, OceanconnectWeb.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false

# watchers: [yarn: ["run", "watch", cd: Path.expand("../assets", __DIR__)]]

# ## SSL Support
#
# In order to use HTTPS in development, a self-signed
# certificate can be generated by running the following
# command from your terminal:
#
#     openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=www.example.com" -keyout priv/server.key -out priv/server.pem
#
# The `http:` config above can be replaced with:
#
#     https: [port: 4000, keyfile: "priv/server.key", certfile: "priv/server.pem"],
#
# If desired, both `http:` and `https:` keys can be
# configured to run both http and https servers on
# different ports.

# Watch static and templates for browser reloading.
config :oceanconnect, OceanconnectWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r{priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$},
      ~r{priv/gettext/.*(po)$},
      ~r{lib/oceanconnect_web/views/.*(ex)$},
      ~r{lib/oceanconnect_web/templates/.*(eex)$}
    ]
  ]


# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n", level: :debug, handle_sasl_reports: true

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Configure your database
config :oceanconnect, Oceanconnect.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: System.get_env("DATA_DB_USER") || "postgres",
  password: System.get_env("DATA_DB_PASS") || "changeme",
  hostname: System.get_env("DATA_DB_HOST") || "localhost",
  database: "oceanconnect_dev",
  pool_size: 10

config :oceanconnect, OceanconnectWeb.Mailer, adapter: Bamboo.LocalAdapter

if File.exists?("config/dev.secret.exs") do
  import_config "dev.secret.exs"
end
