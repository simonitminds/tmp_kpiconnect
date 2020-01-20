defmodule Oceanconnect.Repo.Migrations.AddFinalizedToAuction do
  use Ecto.Migration

  def change do
    alter table(:auctions) do
      add(:finalized, :boolean, default: false)
    end
  end
end
