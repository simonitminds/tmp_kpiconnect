defmodule Oceanconnect.Repo.Migrations.CreateTermAuctionVessels do
  use Ecto.Migration

  def change do
    create table("term_auction_vessels") do
      add(:vessel_id, references(:vessels))
      add(:auction_id, references(:term_auctions))
    end
  end
end
