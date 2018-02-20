defmodule Oceanconnect.Repo.Migrations.ChangeBuyerToCompanyOnAuction do
  use Ecto.Migration

  def up do
    alter table(:auctions) do
      remove :buyer_id
      add :buyer_id, references(:companies)
    end
  end

  def down do
    alter table(:auctions) do
      remove :buyer_id
      add :buyer_id, references(:users)
    end
  end
end
