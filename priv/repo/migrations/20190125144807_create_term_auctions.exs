defmodule Oceanconnect.Repo.Migrations.CreateTermAuctions do
  use Ecto.Migration

  def change do
    create table(:term_auctions) do
      add(:type, :string)
      add(:start_date, :utc_datetime_usec)
      add(:end_date, :utc_datetime_usec)
      add(:terminal, :string)
      add(:po, :string)
      add(:port_agent, :string)
      add(:scheduled_start, :utc_datetime_usec)
      add(:auction_started, :utc_datetime_usec)
      add(:auction_ended, :utc_datetime_usec)
      add(:auction_closed_time, :utc_datetime_usec)
      add(:duration, :integer, default: 10 * 60_000)
      add(:anonymous_bidding, :boolean)
      add(:is_traded_bid_allowed, :boolean)
      add(:additional_information, :string)

      add(:fuel_id, references(:fuels))
      add(:fuel_quantity, :integer)

      add(:port_id, references(:ports))
      add(:buyer_id, references(:companies))

      timestamps()
    end
  end
end
