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
      {:phoenix_ecto, "~> 4.0"},
      {:ecto_sql, "~> 3.0"},
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
      {:pot, "~> 1.0.2"}
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
