defmodule Oceanconnect.Auctions.TermAuctionVessel do
  use Ecto.Schema
  import Ecto.Changeset

  alias __MODULE__
  alias Oceanconnect.Auctions.{Vessel, TermAuction}

  @derive {Poison.Encoder, except: []}
  schema "term_auction_vessels" do
    belongs_to(:vessel, Vessel)
    belongs_to(:auction, TermAuction)
  end

  def changeset(%TermAuctionVessel{} = term_auction_vessel, attrs) do
    term_auction_vessel
    |> cast(attrs, [:vessel_id, :auction_id])
    |> validate_required([:vessel_id, :auction_id])
    |> foreign_key_constraint(:auction_id)
    |> foreign_key_constraint(:vessel_id)
  end
end
