defmodule Oceanconnect.Repo.Migrations.AddBargesTable do
  use Ecto.Migration

  def change do
    create table "barges" do
      add :name, :string
      add :serial_number, :string
      add :fuel_capabilities, :string
      add :capacity, :integer
      add :pumping_rate, :string
      add :double_hull_construction, :boolean
      add :port_id, references("ports")
      add :imo_number, :string
      add :dwt, :string
      add :sire_inspection_date, :naive_datetime
      add :sire_inspection_validity, :boolean
      add :less_than_25_years_old, :boolean
      add :standard_fenders, :boolean
      add :cleared, :boolean

      timestamps()
    end
  end
end
