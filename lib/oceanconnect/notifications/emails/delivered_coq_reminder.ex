defmodule Oceanconnect.Notifications.Emails.DeliveredCOQReminder do
  use Oceanconnect.Notifications.Email

  alias Oceanconnect.Accounts
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{Auction, Solution, TermAuction}

  def generate(auction_id, solution), do: emails(Auctions.get_auction!(auction_id), solution)

  defp emails(auction, %Solution{bids: bids}) do
    suppliers = Enum.map(bids, &Accounts.get_company!(&1.supplier_id))

    suppliers
    |> Enum.map(fn supplier ->
      recipients = Accounts.users_for_companies([supplier])

      fuels_for_supplier = get_fuels_by_supplier(auction, supplier, bids)

      Enum.map(recipients, fn recipient ->
        recipient
        |> base_email()
        |> subject("Please upload fuel certificate(s) for Auction #{auction.id}.")
        |> render(
          "delivered_coq_reminder.html",
          auction: auction,
          fuels: fuels_for_supplier,
          user: recipient
        )
      end)
    end)
    |> List.flatten()
  end

  defp get_fuels_by_supplier(
         %Auction{auction_vessel_fuels: auction_vessel_fuels},
         %Company{id: supplier_id},
         bids
       ) do
    bids
    |> Enum.filter(&(&1.supplier_id == supplier_id))
    |> Enum.map(& &1.vessel_fuel_id)
    |> Enum.map(
      &(auction_vessel_fuels
        |> Enum.filter(fn auction_vessel_fuel ->
          auction_vessel_fuel.id == String.to_integer(&1)
        end)
        |> List.first()
        |> case do
          nil -> []
          auction_vessel_fuel -> Map.get(auction_vessel_fuel, :fuel)
        end)
    )
    |> List.flatten()
  end

  defp get_fuels_by_supplier(%TermAuction{}, _supplier, bids) do
    bids
    |> List.first()
    |> Map.get(:vessel_fuel_id)
    |> Auctions.get_fuel!()

    # |> Enum.filter(&(&1.supplier_id == supplier_id))
    # |> Enum.map(& &1.vessel_fuel_id)
    # |> Enum.map(&Auctions.get_fuel!(&1))
  end
end
