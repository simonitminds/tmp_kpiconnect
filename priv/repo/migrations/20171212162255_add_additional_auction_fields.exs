defmodule Oceanconnect.Repo.Migrations.AddAdditionalAuctionFields do
  use Ecto.Migration

  def change do
    alter table("auctions") do
      add :company, :string
      add :po, :string
      add :eta, :naive_datetime
      add :etd, :naive_datetime
      add :auction_start, :naive_datetime
      add :anonymous_bidding, :boolean
      add :duration, :integer
    end
  end
end
