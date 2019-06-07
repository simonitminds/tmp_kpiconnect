defmodule Oceanconnect.Deliveries.DeliveryEvent do
  alias Oceanconnect.Deliveries.{Claim, ClaimResponse}
  alias Oceanconnect.Auctions.{AuctionEvent, AuctionFixture}
  alias Oceanconnect.Accounts.User

  def fixture_created(
        fixture = %AuctionFixture{id: fixture_id, auction_id: auction_id}
      ) do
    %AuctionEvent{
      id: UUID.uuid4(:hex),
      type: :fixture_created,
      auction_id: auction_id,
      data: %{fixture: fixture},
      time_entered: DateTime.utc_now()
    }
  end

  def fixture_updated(
        original = %AuctionFixture{id: fixture_id, auction_id: auction_id},
        changeset = %Ecto.Changeset{}
      ) do
    %AuctionEvent{
      id: UUID.uuid4(:hex),
      type: :fixture_updated,
      auction_id: auction_id,
      data: %{original: original, updated: changeset},
      time_entered: DateTime.utc_now()
    }
  end

  def claim_created(%Claim{id: claim_id, auction_id: auction_id} = claim, %User{} = user) do
    %AuctionEvent{
      id: UUID.uuid4(:hex),
      auction_id: auction_id,
      type: :claim_created,
      data: %{claim: claim},
      user: user,
      time_entered: DateTime.utc_now()
    }
  end

  def claim_response_created(
        %ClaimResponse{claim_id: claim_id} = response,
        %Claim{auction_id: auction_id} = claim,
        %User{} = user
      ) do
    %AuctionEvent{
      id: UUID.uuid4(:hex),
      auction_id: auction_id,
      type: :claim_response_created,
      data: %{response: response, claim: claim},
      user: user,
      time_entered: DateTime.utc_now()
    }
  end
end
