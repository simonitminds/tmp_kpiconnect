defmodule Oceanconnect.Repo.Migrations.AddScheduledStartToAuction do
  use Ecto.Migration

  def change do
    alter table(:auctions) do
      add :scheduled_start, :naive_datetime
    end

    rename table(:auctions), :auction_start, to: :auction_started
  end
end
