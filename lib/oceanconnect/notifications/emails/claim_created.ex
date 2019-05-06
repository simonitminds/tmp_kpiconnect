defmodule Oceanconnect.Notifications.Emails.ClaimCreated do
  import Oceanconnect.Deliveries.Guards
  use Oceanconnect.Notifications.Email

  alias Oceanconnect.Deliveries

  def generate(%struct{id: claim_id}) when is_claim(struct) do
    case Deliveries.get_quantity_claim(claim_id) do
      nil -> []
      claim -> emails(claim)
    end
  end

  defp emails(
         %{
           type: type,
           auction_id: auction_id,
           fixture: fixture,
           notice_recipient: recipient,
           notice_recipient_type: "supplier"
         } = claim
       ) do
    suppliers = Accounts.users_for_companies([recipient])

    Enum.map(suppliers, fn supplier ->
      base_email(supplier)
      |> subject("A #{String.capitalize(type)} Claim has been made for Auction #{auction_id}")
      |> render("claim_created.html", claim: claim, fixture: fixture, user: supplier)
    end)
  end

  defp emails(
         %{
           type: type,
           auction_id: auction_id,
           fixture: fixture,
           notice_recipient: recipient,
           notice_recipient_type: "admin"
         } = claim
       ) do
    admin_users = Accounts.users_for_companies([recipient])

    Enum.map(admin_users, fn admin ->
      admin_email(admin)
      |> subject("A #{String.capitalize(type)} Claim has been made for Auction #{auction_id}")
      |> render("claim_created.html", claim: claim, fixture: fixture, user: admin)
    end)
  end
end
