defmodule Oceanconnect.Deliveries do
  alias Oceanconnect.Repo

  alias Oceanconnect.Deliveries.{Claim, DeliveryEvent, EventNotifier, ClaimResponse}
  alias Oceanconnect.Auctions.{Auction, TermAuction}
  alias Oceanconnect.Accounts

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

  def create_claim_response(attrs \\ %{}, user) do
    case handle_response_creation(attrs, user) do
      {:ok, response} ->
        response
        |> DeliveryEvent.claim_response_created()
        |> EventNotifier.emit(response)

        {:ok, response}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp handle_response_creation(
         %{"claim_id" => claim_id} = attrs,
         %Accounts.User{company_id: company_id} = user
       ) do
    with %Claim{buyer_id: buyer_id} when buyer_id == company_id <- get_claim(claim_id) do
      %ClaimResponse{}
      |> ClaimResponse.buyer_changeset(attrs)
      |> Repo.insert()
    else
      _ ->
        %ClaimResponse{}
        |> ClaimResponse.changeset(attrs)
        |> Repo.insert()
    end
  end

  defp handle_response_creation(
         %{claim_id: claim_id} = attrs,
         %Accounts.User{company_id: company_id} = user
       ) do
    with %Claim{buyer_id: buyer_id} when buyer_id == company_id <- get_claim(claim_id) do
      %ClaimResponse{}
      |> ClaimResponse.buyer_changeset(attrs)
      |> Repo.insert()
    else
      _ ->
        %ClaimResponse{}
        |> ClaimResponse.changeset(attrs)
        |> Repo.insert()
    end
  end

  defp handle_response(_, _) do
    %ClaimResponse{}
    |> ClaimResponse.changeset(%{})
    |> Repo.insert()
  end

  def get_claim_response(id) do
    Repo.get(ClaimResponse, id)
    |> Repo.preload(
      claim: [:fixture, :receiving_vessel, :delivered_fuel, :buyer, :supplier, auction: :port],
      author: :company
    )
  end
end