defmodule Oceanconnect.Repo.Migrations.AddAuctionBarges do
  use Ecto.Migration

  def change do
    create table "auctions_barges" do
      add :barge_id, references("barges")
      add :auction_id, references("auctions")
      add :supplier_id, references("auction_suppliers")
      add :approval_status, :string
    end
  end
end
