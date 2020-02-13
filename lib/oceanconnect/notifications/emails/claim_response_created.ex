defmodule Oceanconnect.Notifications.Emails.ClaimResponseCreated do
  use Oceanconnect.Notifications.Email

  alias Oceanconnect.Deliveries
  alias Oceanconnect.Deliveries.ClaimResponse

  alias Oceanconnect.Accounts

  def generate(claim_response = %ClaimResponse{}), do: claim_response |> Deliveries.fully_loaded() |> emails()

  defp emails(claim_response = %{
         claim: claim = %{buyer: buyer = %Company{id: company_id}, supplier: supplier},
         author: %{company_id: company_id} = author
       }) do
    recipients = Accounts.users_for_companies([supplier])

    author_name = Accounts.User.full_name(author)

    Enum.map(recipients, fn recipient ->
      base_email(recipient)
      |> subject(
        "#{author_name} from #{buyer.name} added a response to the claim against #{supplier.name}"
      )
      |> render("supplier_claim_response_created.html",
        user: recipient,
        claim: claim,
        claim_response: claim_response,
        author_name: author_name,
        supplier: supplier,
        buyer: buyer
      )
    end)
  end

  defp emails(claim_response = %{
         claim: claim = %{buyer: buyer, supplier: supplier},
         author: author
       }) do
    recipients = Accounts.users_for_companies([buyer])

    author_name = Accounts.User.full_name(author)

    Enum.map(recipients, fn recipient ->
      base_email(recipient)
      |> subject(
        "#{author_name} from #{supplier.name} responded to the claim made by #{buyer.name}"
      )
      |> render("buyer_claim_response_created.html",
        user: recipient,
        claim: claim,
        claim_response: claim_response,
        author_name: author_name,
        supplier: supplier,
        buyer: buyer
      )
    end)
  end
end
