defmodule Oceanconnect.Auctions.Guards do
  alias Oceanconnect.Auctions.{Auction, TermAuction}

  defguard is_auction(type) when type in [Auction, TermAuction]
end
