defmodule Oceanconnect.Repo.Migrations.CreateAuctionFixtureRecord do
  use Ecto.Migration

  def change do
    create table(:auction_fixtures) do
      add :auction_id, references(:auctions, on_delete: :nothing)
      add :auction_vessel_fuel_id, references(:auctions_vessels_fuels, on_delete: :nothing)
      add :supplier_id, references(:companies, on_delete: :nothing)
      add :winning_price, :integer
      add :post_auction_price, :integer
      add :post_auction_quantity, :integer
    end
  end
end
