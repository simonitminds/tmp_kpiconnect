defmodule Oceanconnect.Repo.Migrations.AddTermAuctionIdToAuctionSuppliers do
  use Ecto.Migration

  def change do
    alter table(:auction_suppliers) do
      add(:term_auction_id, references(:term_auctions))
    end
  end
end
