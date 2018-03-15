defmodule Oceanconnect.Repo.Migrations.AddSupplierAliasToAuctionSuppliers do
  use Ecto.Migration

  def change do
    alter table(:auction_suppliers) do
      add :alias_name, :string
    end
  end
end
