defmodule Oceanconnect.Repo.Migrations.AddDeliveredToAuctionSupplieCOQ do
  use Ecto.Migration

  def change do
    alter table(:auction_supplier_coqs) do
      add(:delivered, :boolean, default: false)
    end
  end
end
