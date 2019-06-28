defmodule Oceanconnect.Notifications.Emails.FixtureDelivered do
  use Oceanconnect.Notifications.Email

  alias Oceanconnect.Accounts
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.AuctionFixture

  def generate(%AuctionFixture{} = fixture) do
    emails(fixture)
  end

  defp emails(fixture) do
    (recipients(fixture, :buyer) ++
       recipients(fixture))
    |> emails(fixture)
  end

  defp emails(
         recipients,
         %{auction_id: auction_id, vessel: vessel, delivered_vessel: delivered_vessel} = fixture
       ) do
    vessel =
      cond do
        vessel.id != delivered_vessel.id -> vessel
        true -> vessel
      end

    recipients
    |> Enum.map(fn recipient ->
      base_email(recipient)
      |> subject(
        "A fixture has been marked as delivered for Auction #{auction_id} on #{vessel.name}"
      )
      |> render("fixture_delivered.html",
        user: recipient,
        fixture: fixture
      )
    end)
  end

  defp recipients(%{auction_id: auction_id}, :buyer) do
    %{buyer_id: buyer_id} = Auctions.get_auction!(auction_id)
    buyer = Accounts.get_company!(buyer_id)
    Accounts.users_for_companies([buyer])
  end

  defp recipients(%{supplier_id: supplier_id, delivered_supplier_id: delivered_supplier_id})
       when supplier_id != delivered_supplier_id do
    delivered_supplier = Accounts.get_company!(delivered_supplier_id)
    Accounts.users_for_companies([delivered_supplier])
  end

  defp recipients(%{supplier_id: supplier_id}) do
    supplier = Accounts.get_company!(supplier_id)
    Accounts.users_for_companies([supplier])
  end
end
