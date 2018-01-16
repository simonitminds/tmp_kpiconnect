defmodule Oceanconnect.Repo.Migrations.AddBuyerToAuction do
  use Ecto.Migration

  def change do
    alter table("auctions") do
      add :buyer_id, references(:users)
    end
  end
end
