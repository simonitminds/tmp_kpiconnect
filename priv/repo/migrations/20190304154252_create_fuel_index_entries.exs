defmodule Oceanconnect.Repo.Migrations.CreateFuelIndexEntries do
  use Ecto.Migration

  def change do
    create table(:fuel_index_entries) do
      add :code, :string
      add :name, :string
      add :fuel_id, references(:fuels)
      add :port_id, references(:ports)
      add :is_active, :boolean, default: true

      timestamps()
    end
  end
end
