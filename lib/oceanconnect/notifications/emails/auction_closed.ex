defmodule Oceanconnect.Notifications.Emails.AuctionClosed do
  import Bamboo.Email
  use Bamboo.Phoenix, view: OceanconnectWeb.EmailView
  alias Oceanconnect.Accounts
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{Solution, Guards}

  def generate(auction_state = %{
        auction_id: auction_id,
        winning_solution: solution,
        submitted_barges: barges
      }) do
    auction = Auctions.get_auction(auction_id)
    participants = Auctions.active_participants(auction)
    %Solution{bids: bids} = solution
    approved_barges = Enum.filter(submitted_barges, &(&1.approval_status == "APPROVED"))

    emails(auction, participants, bids, approved_barges)
  end

  defp emails(
        auction = %struct{},
        active_participants,
        bids,
        approved_barges
      ) when is_auction(struct) do
    %{
      buyer_id: buyer_id,
      auction_vessel_fuels: vessel_fuels,
      port: port
    } = auction

    active_user_emails =
      active_participants
      |> Enum.map(& &1.email)

    buyer_company = Accounts.get_company!(buyer_id)

    buyers =
      Accounts.users_for_companies([buyer_company])
      |> Enum.filter(&(&1.email in active_user_emails))

    port_name = port.name

    bids_by_vessel =
      Enum.reduce(bids, %{}, fn bid, acc ->
        vessel_fuel = Enum.find(vessel_fuels, &("#{&1.id}" == bid.vessel_fuel_id))
        if vessel_fuel do
          case acc[vessel_fuel.vessel] do
            nil ->
              Map.put(acc, vessel_fuel.vessel, [bid])

            existing_value ->
              Map.put(acc, vessel_fuel.vessel, [bid | existing_value])
          end
        else
          acc
        end
      end)

    Enum.flat_map(bids_by_vessel, fn {vessel, bids} ->
      bids_by_supplier =
        Enum.reduce(bids, %{}, fn bid, acc ->
          case acc[bid.supplier_id] do
            nil ->
              Map.put(acc, bid.supplier_id, [bid])

            existing_value ->
              Map.put(acc, bid.supplier_id, [bid | existing_value])
          end
        end)

      Enum.map(bids_by_supplier, fn {supplier_id, bids} ->
        supplier_company = Accounts.get_company!(supplier_id)

        suppliers =
          Accounts.users_for_companies([supplier_company])
          |> Enum.filter(&(&1.email in active_user_emails))

        is_traded_bid = Enum.any?(bids, &(&1.is_traded_bid == true))

        deliverables =
          bids
          |> Enum.map(fn bid ->
            Enum.find(vessel_fuels, &("#{&1.id}" == bid.vessel_fuel_id))
            |> Map.put(:bid, bid)
          end)

        supplier_emails =
          Enum.map(suppliers, fn supplier ->
            base_email(supplier)
            |> subject("You have won Auction #{auction.id} for #{vessel.name} at #{port_name}!")
            |> render(
              "auction_completion.html",
              user: supplier,
              winning_supplier_company: supplier_company,
              physical_buyer: buyer_company,
              is_traded_bid: is_traded_bid,
              auction: auction,
              vessel: vessel,
              buyer_company: buyer_company_for_email(is_traded_bid, buyer_company),
              deliverables: deliverables,
              approved_barges:
                approved_barges_for_supplier(approved_barges, supplier_company.id),
              is_buyer: false
            )
          end)

        buyer_emails =
          Enum.map(buyers, fn buyer ->
            base_email(buyer)
            |> subject("Auction #{auction.id} for #{vessel.name} at #{port_name} has closed.")
            |> render(
              "auction_completion.html",
              user: buyer,
              winning_supplier_company:
                supplier_company_for_email(is_traded_bid, buyer_company, supplier_company),
              physical_supplier: supplier_company,
              is_traded_bid: is_traded_bid,
              auction: auction,
              vessel: vessel,
              buyer_company: buyer_company,
              deliverables: deliverables,
              approved_barges:
                approved_barges_for_supplier(approved_barges, supplier_company.id),
              is_buyer: true
            )
          end)

        List.flatten([supplier_emails, buyer_emails])
      end)
    end)
    |> List.flatten()
  end
end
