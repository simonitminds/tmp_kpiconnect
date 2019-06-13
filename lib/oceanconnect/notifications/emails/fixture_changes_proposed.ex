defmodule Oceanconnect.Notifications.Emails.FixtureChangesProposed do
  use Oceanconnect.Notifications.Email

  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.AuctionFixture
  alias Oceanconnect.Accounts
  alias Oceanconnect.Accounts.User

  def generate(%AuctionFixture{} = fixture, %Ecto.Changeset{changes: changes}, %User{} = user) do
    emails(fixture, changes, user)
  end

  defp emails(fixture, changes, user) do
    admin_and_buyer_emails =
      buyer_recipients(fixture) ++
        Accounts.list_admin_users()
        |> emails(fixture, changes, user)

    supplier_emails =
      supplier_recipients(fixture)
      |> emails(Map.drop(fixture, [:supplier_id]), changes, user)

    admin_and_buyer_emails ++ supplier_emails
  end

  defp emails(recipients, %{auction_id: auction_id, vessel: vessel} = fixture, changes, user) do
    {changes, comment} =
      case changes do
        %{comment: comment} ->
          {Map.drop(changes, [:comment]), comment}
        _ ->
          {changes, "No comment was made on this proposition."}
      end

    auction = Auctions.get_auction!(auction_id)

    recipients
    |> Enum.map(fn %{is_admin: is_admin} = recipient ->
      admin_email(recipient)
      |> subject("Post-auction changes have been proposed for Auction #{auction_id} on #{vessel.name}")
      |> render("fixture_changes_proposed.html",
        user: recipient,
        proposing_user: user,
        proposing_company: Accounts.get_company!(user.company_id),
        is_admin: is_admin,
        auction: auction,
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

  defp supplier_recipients(%{supplier_id: supplier_id}) do
    supplier = Accounts.get_company!(supplier_id)
    Accounts.users_for_companies([supplier])
  end
end
