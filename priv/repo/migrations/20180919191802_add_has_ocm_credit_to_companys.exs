defmodule Oceanconnect.Repo.Migrations.AddHasOcmCreditToCompanys do
  use Ecto.Migration

  def change do
    alter table(:companies) do
      add :has_ocm_credit, :boolean, default: false
    end
  end
end
