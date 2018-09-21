defmodule Oceanconnect.Repo.Migrations.AddIsTradedBidToAuctions do
  use Ecto.Migration

  def change do
    alter table(:auctions) do
      add :is_traded_bid, :boolean
    end
  end
end
