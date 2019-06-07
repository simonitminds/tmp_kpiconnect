defmodule Oceanconnect.Repo.Migrations.AddDeliveredToAuctionFixtures do
  use Ecto.Migration

  def change do
    alter table(:auction_fixtures) do
      add :delivered, :boolean, default: false
    end
  end
end
