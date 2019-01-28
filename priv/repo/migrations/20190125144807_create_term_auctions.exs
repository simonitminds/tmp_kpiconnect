defmodule Oceanconnect.Repo.Migrations.AddTermToAuctions do
  use Ecto.Migration

  def change do
    alter table(:auctions) do
      add(:type, :string)
      add(:start_date, :utc_datetime_usec)
      add(:end_date, :utc_datetime_usec)
      add(:terminal, :string)

      # From prior migrations, these fields already exists
      # add(:fuel_id, references(:fuels))
      # add(:fuel_quantity, :integer)
    end

    create table(:term_auction_vessels) do
      add(:auction_id, references(:auctions))
      add(:vessel_id, references(:vessels))
    end
  end
end
