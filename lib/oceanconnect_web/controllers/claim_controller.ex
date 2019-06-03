defmodule OceanconnectWeb.ClaimController do
  use OceanconnectWeb, :controller
  import Oceanconnect.Auctions.Guards
  alias OceanconnectWeb.Plugs.Auth

  alias Oceanconnect.Deliveries
  alias Oceanconnect.Deliveries.{Claim, ClaimResponse}

  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{Auction, AuctionFixture}

  action_fallback(OceanconnectWeb.ErrorController)

  def show(conn, %{"auction_id" => auction_id, "id" => claim_id}) do
    %{id: current_user_id, company_id: current_user_company_id, is_admin: is_admin} =
      Auth.current_user(conn)

    with %Auction{buyer_id: buyer_id} = auction <- Auctions.get_auction!(auction_id),
         %Claim{fixture: fixture} = claim <- Deliveries.get_claim(claim_id) do
      case (current_user_company_id == buyer_id or is_admin) and !claim.closed do
        true ->
          conn
          |> redirect(to: claim_path(conn, :edit, auction.id, claim.id))

        false ->
          changeset = Deliveries.change_claim_response(%ClaimResponse{})

          conn
          |> render("show.html",
            changeset: changeset,
            auction: auction,
            claim: claim,
            fixture: fixture
          )
      end
    end
  end

  def create_response(conn, %{
        "auction_id" => auction_id,
        "id" => claim_id,
        "claim_response" => %{"content" => content} = response_params
      }) do
    current_user =
      %{id: current_user_id, company_id: current_user_company_id, is_admin: is_admin} =
      Auth.current_user(conn)

    with %Auction{suppliers: suppliers, buyer_id: buyer_id} = auction <-
           Auctions.get_auction!(auction_id),
         %Claim{fixture: fixture} = claim <- Deliveries.get_claim(claim_id),
         true <-
           current_user_company_id == buyer_id or
             current_user_company_id in Enum.map(suppliers, & &1.id) or is_admin do
      response_params =
        Map.merge(response_params, %{
          "author_id" => current_user_id,
          "claim_id" => claim_id,
          "content" => content
        })

      case Deliveries.create_claim_response(response_params, claim, current_user) do
        {:ok, _response} ->
          changeset = Deliveries.change_claim_response(%ClaimResponse{})
          claim = Deliveries.get_claim(claim.id)

          conn
          |> put_flash(:info, "Response successfully added.")
          |> put_status(200)
          |> render("show.html",
            changeset: changeset,
            auction: auction,
            claim: claim,
            fixture: fixture
          )

        {:error, %Ecto.Changeset{} = changeset} ->
          conn
          |> put_flash(:error, "Response was not added.")
          |> put_status(400)
          |> render("show.html",
            changeset: changeset,
            auction: auction,
            claim: claim,
            fixture: fixture
          )
      end
    end
  end

  def new(conn, %{"auction_id" => auction_id}) do
    %{company_id: current_user_company_id, is_admin: is_admin} = Auth.current_user(conn)

    with %Auction{buyer_id: buyer_id} = auction
         when buyer_id == current_user_company_id or is_admin <- Auctions.get_auction(auction_id),
         fixtures when not is_nil(fixtures) or fixtures != [] <-
           Auctions.fixtures_for_auction(auction) do
      changeset = Deliveries.change_claim(%Claim{})

      conn
      |> render("new.html",
        changeset: changeset,
        auction: auction,
        fixtures: fixtures,
        claim: nil
      )
    end
  end

  def create(conn, %{"auction_id" => auction_id, "claim" => claim_params}) do
    %{id: current_user_id, company_id: current_user_company_id, is_admin: is_admin} =
      Auth.current_user(conn)

    with %Auction{buyer_id: buyer_id} = auction
         when buyer_id == current_user_company_id or is_admin <-
           Auctions.get_auction!(auction_id),
         fixtures when fixtures != [] or is_nil(fixtures) <-
           Auctions.fixtures_for_auction(auction) do
      claim_params =
        claim_params
        |> build_params_for_claim()
        |> params_from_selected_fixture()
        |> Map.merge(%{
          "auction_id" => auction_id,
          "buyer_id" => buyer_id,
          "author_id" => current_user_id
        })

      case Deliveries.create_claim(claim_params) do
        {:ok, claim} ->
          conn
          |> put_flash(:info, "Claim successfully made.")
          |> redirect(to: claim_path(conn, :edit, auction.id, claim.id))

        {:error, changeset} ->
          conn
          |> put_flash(:error, "Oops, something went wrong! Please check the errors below.")
          |> put_status(400)
          |> render("new.html",
            changeset: changeset,
            auction: auction,
            fixtures: fixtures,
            claim: nil
          )
      end
    end
  end

  defp build_params_for_claim(%{"type" => type} = claim_params) do
    claim_params
    |> Enum.reduce(%{}, fn {key, value}, acc ->
      case key =~ ~r/^#{type}_/ do
        true ->
          key = Regex.replace(~r/^#{type}_/, key, "")

          Map.put(acc, key, value)

        false ->
          Map.put(acc, key, value)
      end
    end)
  end

  defp build_params_for_claim(claim_params), do: claim_params

  defp params_from_selected_fixture(%{"fixture_id" => fixture_id} = claim_params) when fixture_id != "" do
    case Auctions.get_fixture(fixture_id) do
      nil ->
        claim_params

      %AuctionFixture{
        supplier_id: supplier_id,
        vessel_id: vessel_id,
        fuel_id: fuel_id,
        price: price,
        quantity: quantity
      } ->
        Map.merge(claim_params, %{
          "supplier_id" => supplier_id,
          "receiving_vessel_id" => vessel_id,
          "delivered_fuel_id" => fuel_id,
          "price_per_unit" => price
        })

      _ ->
        claim_params
    end
  end

  defp params_from_selected_fixture(claim_params), do: claim_params

  def edit(conn, %{"auction_id" => auction_id, "id" => claim_id}) do
    %{company_id: current_user_company_id, is_admin: is_admin} = Auth.current_user(conn)

    with %Auction{buyer_id: buyer_id} = auction
         when buyer_id == current_user_company_id or is_admin <-
           Auctions.get_auction(auction_id),
         %Claim{fixture: fixture} = claim <- Deliveries.get_claim(claim_id) do
      changeset = Deliveries.change_claim(claim)

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
        "claim" => %{"response" => response} = update_params
      }) do
    current_user =
      %{id: current_user_id, company_id: current_user_company_id, is_admin: is_admin} =
      Auth.current_user(conn)

    with %Auction{buyer_id: buyer_id} = auction
         when buyer_id == current_user_company_id or is_admin <-
           Auctions.get_auction!(auction_id),
         %Claim{fixture: fixture} = claim <- Deliveries.get_claim(claim_id) do
      response_params = %{
        "author_id" => current_user_id,
        "content" => response,
        "claim_id" => claim_id
      }

      with {:ok, claim} <- Deliveries.update_claim(claim, update_params),
           {:ok, claim_reponse} <- Deliveries.create_claim_response(response_params, claim, current_user) do
        case claim.closed do
          true ->
            conn
            |> put_flash(:info, "Claim successfully closed.")
            |> redirect(to: auction_path(conn, :show, auction.id))

          false ->
            changeset = Deliveries.change_claim(claim)

            conn
            |> put_flash(:info, "Claim successfully updated.")
            |> redirect(to: claim_path(conn, :edit, auction.id, claim.id))
        end
      else
        {:error, %Ecto.Changeset{data: %Oceanconnect.Deliveries.Claim{}} = changeset} ->
          render(conn, "edit.html",
            changeset: changeset,
            auction: auction,
            claim: claim,
            fixture: fixture
          )

        {:error, %Ecto.Changeset{data: %Oceanconnect.Deliveries.ClaimResponse{}, errors: errors}} ->
          changeset = Deliveries.change_claim(claim)

          render(conn, "edit.html",
            changeset: %{changeset | errors: errors},
            auction: auction,
            claim: claim,
            fixture: fixture
          )
      end
    end
  end
end
