defmodule Oceanconnect.Repo.Migrations.AddAuctionEventStorageTable do
  use Ecto.Migration

  def change do
    create table(:auction_events) do
      add :auction_id, references(:auctions)
      add :event, :map

      timestamps()
    end
  end
end
