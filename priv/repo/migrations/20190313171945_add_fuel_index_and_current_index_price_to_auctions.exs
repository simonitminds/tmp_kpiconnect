defmodule Oceanconnect.Repo.Migrations.AddFuelIndexAndCurrentIndexPriceToAuctions do
  use Ecto.Migration

  def change do
    alter table (:auctions) do
      add(:fuel_index_id, references(:fuel_index_entries))
      add(:current_index_price, :float)
    end
  end
end
