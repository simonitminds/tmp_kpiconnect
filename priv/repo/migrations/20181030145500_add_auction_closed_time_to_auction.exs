defmodule Oceanconnect.Repo.Migrations.AddAuctionClosedTimeToAuction do
  use Ecto.Migration

  def change do
    alter table(:auctions) do
      add :auction_closed_time, :naive_datetime
    end
  end
end
