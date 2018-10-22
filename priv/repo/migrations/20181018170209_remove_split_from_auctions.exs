defmodule Oceanconnect.Repo.Migrations.RemoveSplitBidAllowedToAuctions do
  use Ecto.Migration

  def up do
    alter table("auctions") do
      remove :split_bid_allowed
    end
  end

  def down do
    alter table("auctions") do
      add :split_bid_allowed, :boolean, default: true
    end
  end
end
