defmodule Oceanconnect.Notifications.Emails.FixtureCreated do
  use Oceanconnect.Notifications.Email

  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.AuctionFixture
  alias Oceanconnect.Accounts

  def generate(%AuctionFixture{id: fixture_id}) do
    Auctions.get_fixture!(fixture_id)
    |> emails()
  end

  defp emails(%{auction_id: auction_id, supplier_id: supplier_id} = fixture) do
    auction = %{buyer_id: buyer_id} = Auctions.get_auction!(auction_id)

    (recipients(buyer_id) ++
       recipients(supplier_id))
    |> emails(fixture, auction)
  end

  defp emails(recipients, %{auction_id: auction_id, vessel: vessel} = fixture, auction) do
    recipients
    |> Enum.map(fn recipient ->
      base_email(recipient)
      |> subject("A fixture has been created for Auction #{auction_id} on #{vessel.name}")
      |> render("fixture_created.html",
        user: recipient,
        fixture: fixture,
        auction: auction
      )
    end)
  end

  defp recipients(company_id) do
    company = Accounts.get_company!(company_id)
    Accounts.users_for_companies([company])
  end
end
