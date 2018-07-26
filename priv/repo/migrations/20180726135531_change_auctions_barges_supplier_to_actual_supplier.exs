defmodule Oceanconnect.Repo.Migrations.ChangeAuctionsBargesSupplierToActualSupplier do
  use Ecto.Migration

  def up do
    drop constraint "auctions_barges", "auctions_barges_supplier_id_fkey"
    alter table "auctions_barges" do
      modify :supplier_id, references("companies")
    end
  end

  def down do
    drop constraint "auctions_barges", "auctions_barges_supplier_id_fkey"
    alter table "auctions_barges" do
      modify :supplier_id, references("auction_suppliers")
    end
  end
end
