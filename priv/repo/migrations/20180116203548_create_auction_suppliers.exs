defmodule Oceanconnect.Repo.Migrations.CreateAuctionSuppliers do
  use Ecto.Migration

  def change do
    create table(:auction_suppliers) do
      add :participation, :string
      add :supplier_id, references(:users, on_delete: :nothing)
      add :auction_id, references(:auctions, on_delete: :nothing)

      timestamps()
    end

    create unique_index(:auction_suppliers, [:auction_id, :supplier_id], name: :unique_auction_supplier)
  end
end
