defmodule Oceanconnect.Repo.Migrations.AddAuctionFixtureToAuctionSupplierCoq do
  use Ecto.Migration

  def change do
    alter table(:auction_supplier_coqs) do
      add(:auction_fixture_id, references(:auction_fixtures, on_delete: :nothing))
    end
  end
end
