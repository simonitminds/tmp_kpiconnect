defmodule Oceanconnect.Repo.Migrations.AddIsOcmToCompanies do
  use Ecto.Migration

  def change do
    alter table(:companies) do
      add :is_ocm, :boolean
    end
  end
end
