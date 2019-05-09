defmodule Oceanconnect.Repo.Migrations.CreateClaims do
  use Ecto.Migration

  def change do
    create table(:claims) do
      add(:type, :string)
      add(:closed, :boolean)
      add(:quantity_missing, :integer)
      add(:price_per_unit, :float)
      add(:total_fuel_value, :float)
      add(:additional_information, :string)
      add(:claim_resolution, :string)
      add(:notice_recipient_type, :string)
      add(:supplier_last_correspondence, :utc_datetime_usec)
      add(:admin_last_correspondence, :utc_datetime_usec)

      add(:buyer_id, references(:companies))
      add(:supplier_id, references(:companies))
      add(:notice_recipient_id, references(:companies))

      add(:receiving_vessel_id, references(:vessels))
      add(:delivered_fuel_id, references(:fuels))
      add(:delivering_barge_id, references(:barges))

      add(:fixture_id, references(:auction_fixtures))
      add(:auction_id, references(:auctions))

      timestamps()
    end
  end
end
