defmodule Oceanconnect.Notifications.Emails.AuctionStartingSoon do
  import Bamboo.Email
  use Bamboo.Phoenix, view: OceanconnectWeb.EmailView
  alias Oceanconnect.Accounts
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.Guards

  def generate(auction_state = %{auction_id: auction_id}) do
    auction_id
    |> Auctions.get_auction()
    |> emails()
  end

  defp emails(%{
      suppliers: supplier_companies,
      buyer: buyer_company,
      vessels: vessels,
      port: port
    } = auction
    ) do
    buyers = buyer_company.users

    vessel_name =
      vessels
      |> Enum.map(& &1.name)
      |> Enum.join(", ")

    port_name = port.name

    suppliers =
      Enum.map(supplier_companies, fn supplier_company ->
        Enum.map(supplier_company.users, fn user -> user end)
      end)
      |> List.flatten()

    supplier_emails =
      Enum.map(suppliers, fn supplier ->
        base_email(supplier)
        |> subject("Auction #{auction.id} for #{vessel_name} at #{port_name} is starting soon.")
        |> render(
          "auction_starting.html",
          user: supplier,
          auction: auction,
          buyer_company: buyer_company,
          is_buyer: false
        )
      end)

    buyer_emails =
      Enum.map(buyers, fn buyer ->
        base_email(buyer)
        |> subject("Auction #{auction.id} for #{vessel_name} at #{port_name} is starting soon.")
        |> render(
          "auction_starting.html",
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
