defmodule Oceanconnect.Notifications.Emails.FixtureUpdated do
  use Oceanconnect.Notifications.Email

  alias Oceanconnect.Accounts
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.AuctionFixture

  def generate(%AuctionFixture{} = fixture, %Ecto.Changeset{changes: changes}) do
    emails(fixture, changes)
  end

  defp emails(fixture, changes) do
    buyer_emails =
      buyer_recipients(fixture)
      |> emails(fixture, changes)

    supplier_emails =
      supplier_recipients(fixture, changes)
      |> emails(Map.drop(fixture, [:supplier_id]), changes)

    buyer_emails ++ supplier_emails
  end

  defp emails(recipients, %{auction_id: auction_id, vessel: vessel} = fixture, changes) do
    {changes, comment} =
      case changes do
        %{comment: comment} ->
          {Map.drop(changes, [:comment]), comment}

        _ ->
          {changes, "No comment was made on this change."}
      end

    recipients
    |> Enum.map(fn recipient ->
      base_email(recipient)
      |> subject(
        "Post-auction changes for Auction #{auction_id} on #{vessel.name} have been made"
      )
      |> render("fixture_updated.html",
        user: recipient,
        fixture: fixture,
        changes: changes,
        comment: comment
      )
    end)
  end

  defp buyer_recipients(%{auction_id: auction_id}) do
    %{buyer_id: buyer_id} = Auctions.get_auction!(auction_id)
    buyer = Accounts.get_company!(buyer_id)
    Accounts.users_for_companies([buyer])
  end

  defp supplier_recipients(%{supplier: supplier}, _changes),
    do: Accounts.users_for_companies([supplier])

  defp supplier_recipients(_fixture, %{supplier_id: supplier_id}) do
    supplier_id
    |> Accounts.get_company!()
    |> List.wrap()
    |> Accounts.users_for_companies()
  end
end
