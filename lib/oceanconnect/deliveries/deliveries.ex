defmodule Oceanconnect.Deliveries do
  alias Oceanconnect.Repo
  import Oceanconnect.Deliveries.Guards

  alias Oceanconnect.Deliveries.{QuantityClaim, DeliveryEvent, EventNotifier, ClaimResponse}
  alias Oceanconnect.Auctions.{Auction, TermAuction}

  def change_quantity_claim(%QuantityClaim{} = claim) do
    QuantityClaim.changeset(claim, %{})
  end

  def create_quantity_claim(attrs \\ %{}) do
    with {:ok, claim} <- create_claim(%QuantityClaim{}, attrs) do
      claim
      |> DeliveryEvent.claim_created()
      |> EventNotifier.emit(claim)

      {:ok, claim}
    else
      error -> error
    end
  end

  defp create_claim(%struct{} = claim, attrs) when is_claim(struct) do
    claim
    |> struct.changeset(attrs)
    |> Repo.insert()
  end

  def update_quantity_claim(%QuantityClaim{} = claim, attrs) do
    claim
    |> QuantityClaim.changeset(attrs)
    |> Repo.update()
  end

  def get_quantity_claim(id) do
    Repo.get(QuantityClaim, id)
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
    |> QuantityClaim.by_auction()
    |> Repo.all()
    |> Repo.preload([:supplier, :delivered_fuel, :receiving_vessel, delivering_barge: [:port]])
  end

  def claims_for_auction(%TermAuction{}), do: []

  def create_claim_response(attrs \\ %{}) do
    %ClaimResponse{}
    |> ClaimResponse.changeset(attrs)
    |> Repo.insert()
  end

  def get_claim_response(id) do
    Repo.get(ClaimResponse, id)
  end
end
