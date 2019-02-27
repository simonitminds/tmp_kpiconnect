defmodule Oceanconnect.Notifications do
  import Ecto.Query, warn: false
  import Oceanconnect.Auctions.Guards

  alias Oceanconnect.Repo
  alias OceanconnectWeb.Email
  alias Oceanconnnect.Auctions

  def emails_for_event(
    event = %AuctionEvent{type: :auction_created},
    auction_state = %state_struct{auction_id: auction_id}
  ) when is_auction_state(auction_state) do
    Emails.AuctionInvitation.generate(auction_state)
  end

  def emails_for_event(
        event = %AuctionEvent{type: :auction_closed},
        auction_state = %state_struct{auction_id: auction_id}
      ) when is_auction_state(auction_state) do
    Emails.AuctionClosed.generate(auction_state)
  end

  def emails_for_event(
    event = %AuctionEvent{type: :auction_rescheduled},
    auction_state = %state_struct{auction_id: auction_id}
  ) when is_auction_state(auction_state) do
    Emails.AuctionRescheduled.generate(auction_state)
  end

  def emails_for_event(
        event = %AuctionEvent{type: :upcoming_auction_notified},
        auction_state = %state_struct{auction_id: auction_id}
      ) when is_auction_state(state_struct) do
    Emails.AuctionStartingSoon.generate(auction_state)
  end

  def emails_for_event(
    event = %AuctionEvent{type: :auction_canceled},
    auction_state = %state_struct{auction_id: auction_id}
  ) when is_auction_state(state_struct) do
    Emails.Auction.AuctionCanceled.generate(auction_state)
  end


end
