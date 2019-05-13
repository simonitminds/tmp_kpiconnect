defmodule Oceanconnect.Repo.Migrations.ChangePricePerUnitAndTotalFuelValueOnClaims do
  use Ecto.Migration

  def change do
    alter table(:claims) do
      modify :price_per_unit, :decimal
      modify :total_fuel_value, :decimal
    end
  end
end
