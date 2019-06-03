defmodule Oceanconnect.Deliveries.DeliveryEvent do
  alias Oceanconnect.Deliveries.{Claim, ClaimResponse}
  alias Oceanconnect.Auctions.{AuctionEvent, AuctionFixture}

  defstruct id: nil,
            type: nil,
            auction_id: nil,
            data: nil,
            time_entered: nil

  def fixture_created(fixture = %AuctionFixture{id: fixture_id, auction_id: auction_id}) do
    %AuctionEvent{
      id: UUID.uuid4(:hex),
      type: :fixture_created,
      auction_id: auction_id,
      data: %{fixture: fixture},
      time_entered: DateTime.utc_now()
    }
  end

  def fixture_updated(original = %AuctionFixture{id: fixture_id, auction_id: auction_id},
    updated = %AuctionFixture{id: fixture_id, auction_id: auction_id}) do
    %AuctionEvent{
      id: UUID.uuid4(:hex),
      type: :fixture_updated,
      auction_id: auction_id,
      data: %{original: original,
              updated: updated},
      time_entered: DateTime.utc_now()
    }
  end

  def claim_created(%Claim{id: claim_id} = claim) do
    %AuctionEvent{
      id: UUID.uuid4(:hex),
      type: :claim_created,
      data: %{claim: claim},
      time_entered: DateTime.utc_now()
    }
  end

  def claim_response_created(%ClaimResponse{claim_id: claim_id} = response, claim) do
    %AuctionEvent{
      id: UUID.uuid4(:hex),
      type: :claim_response_created,
      data: %{response: response, claim: claim},
      time_entered: DateTime.utc_now()
    }
  end
end
