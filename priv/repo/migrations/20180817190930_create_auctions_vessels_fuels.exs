defmodule Oceanconnect.Repo.Migrations.CreateAuctionsVesselsFuels do
  use Ecto.Migration

  def change do
    create table(:auctions_vessels_fuels) do
      add :auction_id, references(:auctions)
      add :vessel_id, references(:vessels)
      add :fuel_id, references(:fuels)
      add :quantity, :integer
    end
  end
end
