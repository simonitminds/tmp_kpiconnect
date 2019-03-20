defmodule Oceanconnect.Notifications.Emails.AuctionClosed do
  alias Oceanconnect.Accounts
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{Auction, TermAuction, Solution}
  import Oceanconnect.Auctions.Guards

  use Oceanconnect.Notifications.Email

  def generate(_auction_state = %state_struct{
        auction_id: auction_id,
        winning_solution: solution,
        submitted_barges: submitted_barges
      }) when is_auction_state(state_struct) do
    auction = Auctions.get_auction(auction_id)
    participants = Auctions.active_participants(auction_id)
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

    supplier_emails = emails_for_users(auction, bids, active_participants, approved_barges, :supplier_emails)
    buyer_emails = emails_for_users(auction, bids, active_participants, approved_barges, :buyer_emails)

    List.flatten(buyer_emails ++ supplier_emails)
  end

  defp emails_for_users(auction = %Auction{buyer_id: buyer_id}, bids, active_participants, approved_barges, email_type) do
    buyer_company = Accounts.get_company!(buyer_id)
    buyers = users_in_auction_for_company(buyer_company, active_participants)

    bids_by_vessel =  bids_by_vessel(auction, bids)

    Enum.flat_map(bids_by_vessel, fn {vessel, bids} ->
      bids_by_supplier = bids_by_supplier(bids)

      Enum.map(bids_by_supplier, fn {supplier_id, bids} ->
        supplier_company = Accounts.get_company!(supplier_id)
        is_traded_bid = Enum.any?(bids, &(&1.is_traded_bid == true))
        deliverables = auction_deliverables(auction, bids)

        email_content = %{
          is_traded_bid: is_traded_bid,
          buyer_company: buyer_company,
          supplier_company: supplier_company,
          deliverables: deliverables,
          approved_barges: approved_barges
        }

        generate_email_templates(auction, email_content, active_participants, vessel, email_type)
      end)
    end)
  end

  defp emails_for_users(auction = %TermAuction{buyer_id: buyer_id}, bids, active_participants, approved_barges, email_type) do
    buyer_company = Accounts.get_company!(buyer_id)
    buyers = users_in_auction_for_company(buyer_company, active_participants)

    bids_by_supplier = bids_by_supplier(bids)

    Enum.flat_map(bids_by_supplier, fn {supplier_id, bids} ->
      supplier_company = Accounts.get_company!(supplier_id)
      is_traded_bid = Enum.any?(bids, &(&1.is_traded_bid == true))
      deliverables = auction_deliverables(auction, bids)

      email_content = %{
        is_traded_bid: is_traded_bid,
        buyer_company: buyer_company,
        supplier_company: supplier_company,
        deliverables: deliverables,
        approved_barges: approved_barges
      }

      generate_email_templates(auction, email_content, active_participants, email_type)
    end)
  end

  defp generate_email_templates(
    auction = %Auction{port: port},
    _email_content = %{
      is_traded_bid: is_traded_bid,
      buyer_company: buyer_company,
      supplier_company: supplier_company,
      deliverables: deliverables,
      approved_barges: approved_barges
    },
    active_participants,
    vessel,
    email_type
  ) do
    port_name = port.name
    case email_type do
      :supplier_emails ->
        suppliers = users_in_auction_for_company(supplier_company, active_participants)
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
      :buyer_emails ->
        buyers = users_in_auction_for_company(buyer_company, active_participants)
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
    end
  end

  defp generate_email_templates(
    auction = %TermAuction{port: port, vessels: vessels},
    _email_content = %{
      is_traded_bid: is_traded_bid,
      buyer_company: buyer_company,
      supplier_company: supplier_company,
      deliverables: deliverables,
      approved_barges: approved_barges
    },
    active_participants,
    email_type
  ) do
    port_name = port.name
    case email_type do
      :supplier_emails ->
        suppliers = users_in_auction_for_company(supplier_company, active_participants)
        Enum.map(suppliers, fn supplier ->
          base_email(supplier)
          |> subject("You have won Auction #{auction.id} at #{port_name}!")
          |> render(
            "auction_completion.html",
            user: supplier,
            winning_supplier_company: supplier_company,
            physical_buyer: buyer_company,
            is_traded_bid: is_traded_bid,
            auction: auction,
            vessels: vessels,
            buyer_company: buyer_company_for_email(is_traded_bid, buyer_company),
            deliverables: deliverables,
            approved_barges:
              approved_barges_for_supplier(approved_barges, supplier_company.id),
            is_buyer: false
          )
        end)
      :buyer_emails ->
        buyers = users_in_auction_for_company(buyer_company, active_participants)
        Enum.map(buyers, fn buyer ->
          base_email(buyer)
          |> subject("Auction #{auction.id} at #{port_name} has closed.")
          |> render(
            "auction_completion.html",
            user: buyer,
            winning_supplier_company:
              supplier_company_for_email(is_traded_bid, buyer_company, supplier_company),
            physical_supplier: supplier_company,
            is_traded_bid: is_traded_bid,
            auction: auction,
            vessels: vessels,
            buyer_company: buyer_company,
            deliverables: deliverables,
            approved_barges:
              approved_barges_for_supplier(approved_barges, supplier_company.id),
            is_buyer: true
          )
        end)
    end
  end

  # TODO: MOVE THESE TO AUCTIONS Context
  defp users_in_auction_for_company(company, active_participants) do
    active_user_ids =
      active_participants
      |> Enum.map(& &1.id)
    Accounts.users_for_companies([company])
    |> Enum.filter(&(&1.id in active_user_ids))
  end

  defp auction_deliverables(%TermAuction{vessels: vessels, fuel: fuel, fuel_quantity: fuel_quantity}, bids) do
    bids
    |> Enum.map(fn bid -> (
      %{
        fuel: fuel,
        quantity: fuel_quantity
      }
      |> Map.put(:bid, bid))
    end)
  end

  defp auction_deliverables(%Auction{auction_vessel_fuels: vessel_fuels}, bids) do
    bids
    |> Enum.map(fn bid ->
      Enum.find(vessel_fuels, &("#{&1.id}" == bid.vessel_fuel_id))
      |> Map.put(:bid, bid)
    end)
  end

  defp bids_by_vessel(%Auction{auction_vessel_fuels: vessel_fuels}, bids) do
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
  end

  defp bids_by_vessels(_, _), do: nil

  defp bids_by_supplier(bids) do
    Enum.reduce(bids, %{}, fn bid, acc ->
      case acc[bid.supplier_id] do
        nil ->
          Map.put(acc, bid.supplier_id, [bid])

        existing_value ->
          Map.put(acc, bid.supplier_id, [bid | existing_value])
      end
    end)
  end
end
