defmodule Oceanconnect.Mixfile do
  use Mix.Project

  def project do
    [
      app: :oceanconnect,
      version: "0.0.1",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Oceanconnect.Application, []},
      extra_applications: [
        :comeonin,
        :scrivener_ecto,
        :sasl,
        :logger,
        :runtime_tools,
        :bamboo,
        :os_mon
      ]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:ex_aws, "~> 2.0"},
      {:ex_aws_s3, "~> 2.0"},
      {:poison, "~> 3.1"},
      {:sweet_xml, "~> 0.6"},
      {:bamboo, "~> 2.2.0"},
      {:bamboo_phoenix, "~> 1.0"},
      {:bcrypt_elixir, "~> 3.0"},
      {:comeonin, "~> 5.3.3"},
      {:cowboy, "~> 2.7"},
      {:plug_cowboy, "~> 2.2"},
      {:phoenix, "~> 1.6.0"},
      {:phoenix_live_dashboard, "~> 0.5"},
      {:phoenix_ecto, "~> 4.0"},
      {:ecto_sql, "~> 3.0"},
      {:ecto_psql_extras, "~> 0.6"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 3.2"},
      {:phoenix_live_reload, "~> 1.0", only: :dev},
      {:ex_machina, "~> 2.2"},
      {:hackney, "~> 1.14"},
      {:hound, "~> 1.1", only: :test},
      {:guardian, "~> 2.2.3"},
      {:guardian_phoenix, "~> 2.0"},
      {:gettext, "~> 0.16"},
      {:scrivener_ecto, "~> 2.0"},
      {:uuid, "~> 1.1"},
      {:pot, "~> 1.0.2"},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},
      {:telemetry_poller, "~> 0.4"},
      {:telemetry_metrics, "~> 0.4"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "assets.deploy": ["phx.digest"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
