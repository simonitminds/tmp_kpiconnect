defmodule Oceanconnect.Repo.Migrations.AddFuelToAuction do
  use Ecto.Migration

  def change do
    alter table("auctions") do
      add :fuel_id, references(:fuels)
    end
  end
end
