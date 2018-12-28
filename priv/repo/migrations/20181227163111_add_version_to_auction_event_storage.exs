defmodule Oceanconnect.Repo.Migrations.AddVersionToAuctionEventStorage do
  use Ecto.Migration

  def change do
    alter table(:auction_events) do
      add :version, :integer
    end
  end
end
