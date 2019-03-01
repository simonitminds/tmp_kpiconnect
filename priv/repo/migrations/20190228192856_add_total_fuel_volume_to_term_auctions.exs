defmodule Oceanconnect.Repo.Migrations.AddTotalFuelVolumeToTermAuctions do
  use Ecto.Migration

  def change do
    alter table(:auctions) do
      add :total_fuel_volume, :integer
      add :show_total_fuel_volume, :boolean, default: true
    end
  end
end
