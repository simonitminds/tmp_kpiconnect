defmodule Oceanconnect.Notifications.Emails.AuctionInvitation do
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
           buyer: buyer,
           port: port,
           suppliers: supplier_companies,
           vessels: vessels,
           type: type
         } = auction
       ) do
    suppliers = Accounts.users_for_companies(supplier_companies)

    vessel_name_list =
      case vessels do
        [] ->
          nil

        vessels ->
          name_list =
            vessels
            |> Enum.map(& &1.name)
            |> Enum.join(", ")

          "for " <> name_list <> " "
      end

    auction_type =
      case type do
        "spot" -> nil
        "formula_related" -> "Formula-Related "
        "forward_fixed" -> "Forward-Fixed "
        _ -> nil
      end

    port_name = port.name

    Enum.map(suppliers, fn supplier ->
      base_email(supplier)
      |> subject(
        "You have been invited to #{auction_type}Auction #{auction.id} #{vessel_name_list}at #{
          port_name
        }"
      )
      |> render(
        "auction_invitation.html",
        supplier: supplier,
        auction: auction,
        buyer_company: buyer
      )
    end)
  end
end
