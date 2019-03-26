defmodule Oceanconnect.Notifications.Emails.AuctionCanceled do
  alias Oceanconnect.Accounts
  alias Oceanconnect.Auctions
  use Oceanconnect.Notifications.Email

  def generate(_auction_state = %{auction_id: auction_id}) do
    auction_id
    |> Auctions.get_auction()
    |> emails()
  end

  defp emails(
         %{
           suppliers: supplier_companies,
           buyer_id: buyer_id,
           vessels: vessels,
           port: port
         } = auction
       ) do
    buyer_company = Accounts.get_company!(buyer_id)
    buyers = Accounts.users_for_companies([buyer_company])
    suppliers = Accounts.users_for_companies(supplier_companies)

    vessel_name =
      vessels
      |> Enum.map(& &1.name)
      |> Enum.join(", ")

    port_name = port.name

    supplier_emails =
      Enum.map(suppliers, fn supplier ->
        base_email(supplier)
        |> subject("Auction #{auction.id} for #{vessel_name} at #{port_name} cancelled.")
        |> render(
          "auction_cancellation.html",
          user: supplier,
          auction: auction,
          buyer_company: buyer_company,
          is_buyer: false
        )
      end)

    buyer_emails =
      Enum.map(buyers, fn buyer ->
        base_email(buyer)
        |> subject("You have canceled Auction #{auction.id} for #{vessel_name} at #{port_name}.")
        |> render(
          "auction_cancellation.html",
          user: buyer,
          auction: auction,
          buyer_company: buyer_company,
          is_buyer: true
        )
      end)

    %{supplier_emails: supplier_emails, buyer_emails: buyer_emails}
    List.flatten([supplier_emails | buyer_emails])
  end
end
