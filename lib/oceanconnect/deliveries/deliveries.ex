defmodule Oceanconnect.Deliveries do
  alias Oceanconnect.Repo

  alias Oceanconnect.Deliveries.{Claim, DeliveryEvent, EventNotifier, ClaimResponse}
  alias Oceanconnect.Auctions.{Auction, TermAuction}

  def change_claim(%Claim{} = claim) do
    Claim.changeset(claim, %{})
  end

  def create_claim(attrs \\ %{}) do
    case %Claim{}
         |> Claim.changeset(attrs)
         |> Repo.insert() do
      {:ok, claim} ->
        claim
        |> DeliveryEvent.claim_created()
        |> EventNotifier.emit(claim)

        {:ok, claim}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def update_claim(%Claim{} = claim, attrs) do
    claim
    |> Claim.changeset(attrs)
    |> Repo.update()
  end

  def get_claim(id) do
    Repo.get(Claim, id)
    |> Repo.preload([
      :delivered_fuel,
      :receiving_vessel,
      :delivering_barge,
      :buyer,
      :supplier,
      :notice_recipient,
      responses: [author: [:company]],
      auction: [:port],
      fixture: [:vessel, :fuel]
    ])
  end

  def claims_for_auction(%Auction{id: auction_id}) do
    auction_id
    |> Claim.by_auction()
    |> Repo.all()
    |> Repo.preload([:supplier, :delivered_fuel, :receiving_vessel, delivering_barge: [:port]])
  end

  def claims_for_auction(%TermAuction{}), do: []

  def change_claim_response(%ClaimResponse{} = response) do
    ClaimResponse.changeset(response, %{})
  end

  def create_claim_response(attrs \\ %{}) do
    %ClaimResponse{}
    |> ClaimResponse.changeset(attrs)
    |> Repo.insert()
  end

  def get_claim_response(id) do
    Repo.get(ClaimResponse, id)
  end
end
