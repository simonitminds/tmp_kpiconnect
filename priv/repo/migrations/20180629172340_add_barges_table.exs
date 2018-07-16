defmodule Oceanconnect.Repo.Migrations.AddBargesTable do
  use Ecto.Migration

  def change do
    create table "barges" do
      add :name, :string
      add :supplier_id, references("companies")
      add :port_id, references("ports")
      add :approval_status, :string
      add :acceptability, :string
      add :imo_number, :string
      add :dwt, :string
      add :bvq_date, :naive_datetime
      add :bvq_validity, :string
      add :sire_inspection_date, :naive_datetime
      add :sire_inspection_validity, :string

      timestamps()
    end
  end
end
