defmodule Oceanconnect.Repo.Migrations.AddBargesTable do
  use Ecto.Migration

  def change do
    create table "barges" do
      add :name, :string
      add :port_id, references("ports")
      add :imo_number, :string
      add :dwt, :string
      add :sire_inspection_date, :naive_datetime
      add :sire_inspection_validity, :boolean

      timestamps()
    end
  end
end
