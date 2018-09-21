defmodule Oceanconnect.Repo.Migrations.AddCreditMarginAmountToCompanies do
  use Ecto.Migration

  def change do
    alter table(:companies) do
      add :credit_margin_amount, :float
    end
  end
end
