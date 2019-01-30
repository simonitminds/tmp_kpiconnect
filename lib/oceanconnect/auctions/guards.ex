defmodule Oceanconnect.Auctions.Guards do
  alias Oceanconnect.Auctions.{Auction, TermAuction, SpotAuctionState, TermAuctionState}

  defguard is_auction(type) when type in [Auction, TermAuction]

  defguard is_auction_state(type) when type in [SpotAuctionState, TermAuctionState]
end
