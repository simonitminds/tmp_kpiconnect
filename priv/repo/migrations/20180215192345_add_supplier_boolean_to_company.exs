defmodule Oceanconnect.Repo.Migrations.AddSupplierBooleanToCompany do
  use Ecto.Migration

  def change do
    alter table("companies") do
      add :is_supplier, :boolean
    end
  end
end
