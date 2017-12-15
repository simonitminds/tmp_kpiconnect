defmodule Oceanconnect.Repo.Migrations.CreatePorts do
  use Ecto.Migration

  def change do
    create table(:ports) do
      add :name, :string

      timestamps()
    end

  end
end
