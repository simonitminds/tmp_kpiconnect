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

  def generate(_auction_supplier_coq), do: []

  defp emails(auction = %{buyer: buyer}, %AuctionSupplierCOQ{
         auction_fixture_id: auction_fixture_id,
         supplier_id: supplier_id
       }) do
    fixture = Auctions.get_auction_supplier_coq(auction_fixture_id, supplier_id).auction_fixture

    [buyer]
    |> Accounts.users_for_companies()
    |> Enum.map(fn recipient ->
      recipient
      |> base_email()
      |> subject("The COQ has been uploaded in Auction #{auction.id} at #{auction.port.name}")
      |> render(
        "delivered_coq_uploaded.html",
        auction: auction,
        fixture: fixture,
        user: recipient
      )
    end)
  end
end
