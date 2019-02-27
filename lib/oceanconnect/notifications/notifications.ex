defmodule Oceanconnect.Notifications do
  import Ecto.Query, warn: false
  import Oceanconnect.Auctions.Guards

  alias Oceanconnect.Repo
  alias OceanconnectWeb.Email
  alias Oceanconnnect.Auctions


  def emails_for_event(
        event = %AuctionEvent{type: :auction_closed},
        auction_state = %state_struct{auction_id: auction_id}
      ) when is_auction_state(state) do
    Emails.AuctionClosed.generate(auction_state)
  end
end
