defmodule Oceanconnect.Repo.Migrations.AddDeliveredDataToAuctionFixtures do
  use Ecto.Migration

  def change do
    alter table(:auction_fixtures) do
      add :delivered_supplier_id, references(:companies, on_delete: :nothing)
      add :delivered_vessel_id, references(:vessels, on_delete: :nothing)
      add :delivered_fuel_id, references(:fuels, on_delete: :nothing)

      add :delivered_price, :decimal
      add :delivered_quantity, :integer
      add :delivered_eta, :utc_datetime_usec
      add :delivered_etd, :utc_datetime_usec
    end
  end
end
