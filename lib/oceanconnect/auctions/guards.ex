defmodule Oceanconnect.Auctions.Guards do
  alias Oceanconnect.Auctions.{
    Auction,
    TermAuction,
    AuctionStore.AuctionState,
    AuctionStore.TermAuctionState
  }

  @spec is_auction(any) ::
          {:__block__ | {:., [], [:erlang | :orelse, ...]}, [],
           [{:= | {any, any, any}, [], [...]}, ...]}
  defguard is_auction(type) when type in [Auction, TermAuction]

  defguard is_auction_state(type) when type in [AuctionState, TermAuctionState]
end
