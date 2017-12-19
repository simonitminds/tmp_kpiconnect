defmodule Oceanconnect.Repo.Migrations.AddVesselToAuction do
  use Ecto.Migration

  def up do
    alter table("auctions") do
      remove :vessel
      add :vessel_id, references(:vessels)
    end
  end

  def down do
    alter table("auctions") do
      remove :vessel_id
      add :vessel, :string
    end
  end
end
