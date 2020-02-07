defmodule Oceanconnect.Notifications.Emails.DeliveredCOQUploaded do
  use Oceanconnect.Notifications.Email

  alias Oceanconnect.Accounts
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.AuctionSupplierCOQ

  def generate(
        auction_supplier_coq = %AuctionSupplierCOQ{
          auction_id: nil,
          term_auction_id: term_auction_id
        }
      ),
      do: emails(Auctions.get_auction!(term_auction_id), auction_supplier_coq)

  def generate(auction_supplier_coq = %AuctionSupplierCOQ{auction_id: auction_id}),
    do: emails(Auctions.get_auction!(auction_id), auction_supplier_coq)

  defp emails(auction = %{buyer: buyer}, %AuctionSupplierCOQ{
         fuel_id: fuel_id,
         supplier_id: supplier_id
       }) do
    fuel = Auctions.get_fuel!(fuel_id)
    supplier = Accounts.get_company!(supplier_id)

    [buyer]
    |> Accounts.users_for_companies()
    |> Enum.map(fn recipient ->
      recipient
      |> base_email()
      |> subject(
        "A Certificate of Quality has been added by #{supplier.name} on Auction #{auction.id} for #{
          fuel.name
        }"
      )
      |> render(
        "delivered_coq_uploaded.html",
        auction: auction,
        fuel: fuel,
        supplier: supplier,
        user: recipient
      )
    end)
  end
end
