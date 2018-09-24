defmodule Oceanconnect.Repo.Migrations.AddIsTradedBidAllowedToAuctions do
  use Ecto.Migration

  def change do
    alter table(:auctions) do
      add :is_traded_bid_allowed, :boolean
    end
  end
end
