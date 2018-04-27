defmodule Oceanconnect.Repo.Migrations.AddAuctionEndTimeToAuction do
  use Ecto.Migration

  def change do
    alter table(:auctions) do
      add :auction_ended, :naive_datetime
    end
  end
end
