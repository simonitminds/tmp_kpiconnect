defmodule Oceanconnect.Auctions.TermAuctionVessel do
  use Ecto.Schema
  import Ecto.{Changeset, Query}
  alias Oceanconnect.Auctions.{Vessel, TermAuction, TermAuctionVessel}

  schema "term_auction_vessels" do
    belongs_to(:vessel, Vessel)
    belongs_to(:auction, TermAuction)

    timestamps()
  end
end
