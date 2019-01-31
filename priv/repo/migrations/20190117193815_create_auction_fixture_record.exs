defmodule Oceanconnect.Repo.Migrations.CreateAuctionFixtureRecord do
  use Ecto.Migration

  def change do
    create table(:auction_fixtures) do
      add :auction_id, references(:auctions, on_delete: :nothing)
      add :supplier_id, references(:companies, on_delete: :nothing)
      add :vessel_id, references(:vessels, on_delete: :nothing)
      add :fuel_id, references(:fuels, on_delete: :nothing)

      add :price, :decimal
      add :quantity, :integer
      add :eta, :utc_datetime_usec
      add :etd, :utc_datetime_usec

      add :original_auction_id, references(:auctions, on_delete: :nothing)
      add :original_supplier_id, references(:companies, on_delete: :nothing)
      add :original_vessel_id, references(:vessels, on_delete: :nothing)
      add :original_fuel_id, references(:fuels, on_delete: :nothing)

      add :original_price, :decimal
      add :original_quantity, :integer
      add :original_eta, :utc_datetime_usec
      add :original_etd, :utc_datetime_usec
    end
  end
end
