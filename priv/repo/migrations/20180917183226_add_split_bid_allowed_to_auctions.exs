defmodule Oceanconnect.Repo.Migrations.AddSplitBidAllowedToAuctions do
  use Ecto.Migration

  def change do
    alter table("auctions") do
      add :split_bid_allowed, :boolean, default: true
    end
  end
end
