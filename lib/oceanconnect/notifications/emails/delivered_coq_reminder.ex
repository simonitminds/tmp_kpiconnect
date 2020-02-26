defmodule Oceanconnect.Notifications.Emails.DeliveredCOQReminder do
  use Oceanconnect.Notifications.Email

  alias Oceanconnect.Accounts
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{Auction, Solution}

  def generate(auction_id, solution),
    do: auction_id |> Auctions.get_auction!() |> Auctions.fully_loaded() |> emails(solution)

  # TODO: The email(s) could have been produced without the solution using just the fixtures to get
  #       the supplier list. It could also be triggered by a Fixture Created/Updated Event
  defp emails(auction = %Auction{fixtures: fixtures, port: port}, %Solution{bids: bids}) do
    suppliers = bids |> Enum.map(&Accounts.get_company!(&1.supplier_id)) |> Enum.uniq()

    suppliers
    |> Enum.map(fn supplier ->
      recipients = Accounts.users_for_companies([supplier])

      fixtures =
        Enum.filter(
          fixtures,
          &(&1.supplier_id == supplier.id &&
              !Auctions.get_auction_supplier_coq(&1.id, &1.supplier_id))
        )

      Enum.map(recipients, fn recipient ->
        recipient
        |> base_email()
        |> subject("The e.t.a. Auction #{auction.id} at #{port.name} is approaching.")
        |> render(
          "delivered_coq_reminder.html",
          auction: auction,
          fixtures: fixtures,
          user: recipient
        )
      end)
    end)
    |> List.flatten()
  end
end
