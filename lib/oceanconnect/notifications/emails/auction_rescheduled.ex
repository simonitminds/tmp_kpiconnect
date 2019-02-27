defmodule Oceanconnect.Notifications.Emails.AuctionRescheduled do
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

  defp emails(
    %{buyer: buyer,
      port: port,
      suppliers: supplier_companies,
      vessels: vessels} = auction
       ) do
    suppliers = Accounts.users_for_companies(supplier_companies)

    vessel_name_list =
      vessels
      |> Enum.map(& &1.name)
      |> Enum.join(", ")

    port_name = port.name

    Enum.map(suppliers, fn supplier ->
      base_email(supplier)
      |> subject(
        "The start time for Auction #{auction.id} for #{vessel_name_list} at #{port_name} has been changed"
      )
      |> render(
        "auction_updated.html",
        supplier: supplier,
        auction: auction,
        buyer_company: buyer
      )
    end)
  end
end
