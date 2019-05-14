defmodule Oceanconnect.Notifications.Emails.ClaimResponseCreated do
  use Oceanconnect.Notifications.Email

  alias Oceanconnect.Deliveries
  alias Oceanconnect.Deliveries.ClaimResponse

  alias Oceanconnect.Accounts

  def generate(%ClaimResponse{id: response_id}) do
    case Deliveries.get_claim_response(response_id) do
      nil ->
        []

      response ->
        emails(response)
    end
  end

  defp emails(%{
         claim: %{buyer_id: buyer_id, supplier: supplier} = claim,
         author: %{company_id: company_id} = author
       })
       when buyer_id == company_id do
    buyer = Accounts.get_company!(buyer_id)
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
        author_name: author_name,
        supplier: supplier,
        buyer: buyer
      )
    end)
  end

  defp emails(%{
         claim: %{buyer: buyer, supplier: supplier} = claim,
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
        author_name: author_name,
        supplier: supplier,
        buyer: buyer
      )
    end)
  end
end
