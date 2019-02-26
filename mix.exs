defmodule Oceanconnect.Mixfile do
  use Mix.Project

  def project do
    [
      app: :oceanconnect,
      version: "0.0.1",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      deploy_dir: "/opt/ocm/oceanconnect/",
      mix_systemd: [
        # Enable restart from flag file
        restart_flag: true,
        # Enable conform config file
        conform: true,
        # Enable chroot
        chroot: true,
        # Enable extra restrictions
        paranoia: true,
        base_path: "/opt/ocm/oceanconnect"
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Oceanconnect.Application, []},
      extra_applications: [:comeonin, :scrivener_ecto, :sasl, :logger, :runtime_tools, :bamboo]
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
      {:bamboo, "~> 1.1"},
      {:bcrypt_elixir, "~> 1.1"},
      {:comeonin, "~> 4.0"},
      {:cowboy, "~> 1.0"},
      {:plug_cowboy, "~> 1.0"},
      {:distillery, "~> 1.5", runtime: false},
      {:phoenix, "~> 1.3.0"},
      {:phoenix_pubsub, "~> 1.1"},
      {:phoenix_ecto, "~> 4.0"},
      {:ecto_sql, "~> 3.0"},
      {:postgrex, "~> 0.14"},
      {:phoenix_html, "~> 2.10"},
      {:phoenix_live_reload, "~> 1.0", only: :dev},
      {:ex_machina, "~> 2.2"},
      {:hackney, "~> 1.14"},
      {:hound, "~> 1.0", only: :test},
      {:guardian, "~> 1.2.1"},
      {:gettext, "~> 0.16"},
      {:scrivener_ecto, "~> 2.0"},
      {:uuid, "~> 1.1"},
      {:pot, "~> 0.9.6"}
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
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
