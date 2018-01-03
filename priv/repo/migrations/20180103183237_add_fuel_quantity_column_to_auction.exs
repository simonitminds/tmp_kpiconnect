defmodule Oceanconnect.Repo.Migrations.AddFuelQuantityColumnToAuction do
  use Ecto.Migration

  def change do
    alter table("auctions") do
      add :fuel_quantity, :integer
    end
  end
end
