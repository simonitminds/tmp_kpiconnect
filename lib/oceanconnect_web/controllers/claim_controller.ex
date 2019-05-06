defmodule OceanconnectWeb.ClaimController do
  use OceanconnectWeb, :controller
  import Oceanconnect.Auctions.Guards
  alias OceanconnectWeb.Plugs.Auth

  alias Oceanconnect.Deliveries
  alias Oceanconnect.Deliveries.{QuantityClaim, ClaimResponse}

  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.Auction

  action_fallback(OceanconnectWeb.ErrorController)

  def show(conn, %{"auction_id" => auction_id, "id" => claim_id}) do
    with %struct{} = auction when is_auction(struct) <- Auctions.get_auction!(auction_id),
         %QuantityClaim{} = claim <- Deliveries.get_quantity_claim(claim_id) do
      conn
      |> render("show.html", auction: auction, claim: claim)
    end
  end

  def new(conn, %{"auction_id" => auction_id}) do
    %{company_id: current_user_company_id, is_admin: is_admin} = Auth.current_user(conn)

    with %Auction{buyer_id: buyer_id} = auction
         when buyer_id == current_user_company_id or is_admin <- Auctions.get_auction(auction_id),
         fixtures when not is_nil(fixtures) or fixtures != [] <-
           Auctions.fixtures_for_auction(auction) do
      changeset = Deliveries.change_quantity_claim(%QuantityClaim{})

      conn
      |> render("new.html",
        changeset: changeset,
        auction: auction,
        fixtures: fixtures,
        claim: nil
      )
    end
  end

  def create(conn, %{"auction_id" => auction_id, "quantity_claim" => claim_params}) do
    %{id: current_user_id, company_id: current_user_company_id, is_admin: is_admin} =
      Auth.current_user(conn)

    with %Auction{buyer_id: buyer_id} = auction
         when buyer_id == current_user_company_id or is_admin <-
           Auctions.get_auction!(auction_id),
         fixtures when fixtures != [] or is_nil(fixtures) <-
           Auctions.fixtures_for_auction(auction) do
      claim_params =
        Map.merge(claim_params, %{
          "auction_id" => auction_id,
          "buyer_id" => buyer_id,
          "author_id" => current_user_id
        })

      case Deliveries.create_quantity_claim(claim_params) do
        {:ok, claim} ->
          conn
          |> put_flash(:info, "Claim successfully made.")
          |> redirect(to: claim_path(conn, :show, auction.id, claim.id))

        {:error, %Ecto.Changeset{} = changeset} ->
          render(conn, "new.html",
            changeset: changeset,
            auction: auction,
            fixtures: fixtures,
            claim: nil
          )
      end
    end
  end

  def edit(conn, %{"auction_id" => auction_id, "id" => claim_id}) do
    %{company_id: current_user_company_id, is_admin: is_admin} = Auth.current_user(conn)

    with %Auction{buyer_id: buyer_id} = auction
         when buyer_id == current_user_company_id or is_admin <-
           Auctions.get_auction(auction_id),
         %QuantityClaim{fixture: fixture} = claim <- Deliveries.get_quantity_claim(claim_id) do
      changeset = Deliveries.change_quantity_claim(claim)

      conn
      |> render("edit.html",
        changeset: changeset,
        auction: auction,
        claim: claim,
        fixture: fixture
      )
    end
  end

  def update(conn, %{
        "auction_id" => auction_id,
        "id" => claim_id,
        "quantity_claim" => %{"response" => response} = update_params
      }) do
    %{id: current_user_id, company_id: current_user_company_id, is_admin: is_admin} =
      Auth.current_user(conn)

    with %Auction{buyer_id: buyer_id} = auction
         when buyer_id == current_user_company_id or is_admin <-
           Auctions.get_auction!(auction_id),
         %QuantityClaim{fixture: fixture} = claim <- Deliveries.get_quantity_claim(claim_id) do
      response_params = %{
        "author_id" => current_user_id,
        "content" => response,
        "quantity_claim_id" => claim_id
      }

      with {:ok, claim} <- Deliveries.update_quantity_claim(claim, update_params),
           {:ok, claim_reponse} <- Deliveries.create_claim_response(response_params) do
        case claim.closed do
          true ->
            conn
            |> put_flash(:info, "Claim successfully closed.")
            |> redirect(to: auction_path(conn, :show, auction.id))

          false ->
            changeset = Deliveries.change_quantity_claim(claim)
            conn
            |> put_flash(:info, "Claim successfully updated.")
            |> redirect(to: claim_path(conn, :edit, auction.id, claim.id))
        end
      else
        {:error, %Ecto.Changeset{data: %Oceanconnect.Deliveries.QuantityClaim{}} = changeset} ->
          render(conn, "new.html",
            changeset: changeset,
            auction: auction,
            claim: claim,
            fixture: fixture
          )

        {:error, %Ecto.Changeset{data: %Oceanconnect.Deliveries.ClaimResponse{}, errors: errors}} ->
          changeset = Deliveries.change_quantity_claim(claim)

          render(conn, "new.html",
            changeset: %{changeset | errors: errors},
            auction: auction,
            claim: claim,
            fixture: fixture
          )
      end
    end
  end
end
