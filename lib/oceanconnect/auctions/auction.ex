defmodule Oceanconnect.Auctions.Auction do
  use Ecto.Schema
  import Ecto.Changeset
  alias Oceanconnect.Auctions.Auction

  schema "auctions" do
    field :port, :string
    field :vessel, :string
    field :company, :string
    field :po, :string
    field :eta, :naive_datetime
    field :etd, :naive_datetime
    field :auction_start, :naive_datetime
    field :duration, :integer
    field :anonymous_bidding, :boolean

    timestamps()
  end

  @doc false
  def changeset(%Auction{} = auction, attrs) do
    auction
    |> cast(attrs, [:vessel, :port, :company, :po, :eta, :etd, :auction_start, :duration, :anonymous_bidding])
    |> validate_required([:vessel, :port])
  end
end
