defmodule Oceanconnect.Repo.Migrations.CreateAuctionSupplierCOQ do
  use Ecto.Migration

  def change do
    create table(:auction_supplier_coqs) do
      add(:file_extension, :string)
      add(:auction_id, references(:auctions, on_delete: :nothing))
      add(:term_auction_id, references(:auctions, on_delete: :nothing))
      add(:supplier_id, references(:companies, on_delete: :nothing))
      add(:fuel_id, references(:fuels, on_delete: :nothing))

      timestamps()
    end
  end
end
