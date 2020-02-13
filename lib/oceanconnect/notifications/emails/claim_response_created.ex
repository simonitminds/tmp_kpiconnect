defmodule Oceanconnect.Notifications.Emails.ClaimResponseCreated do
  use Oceanconnect.Notifications.Email

  alias Oceanconnect.Deliveries
  alias Oceanconnect.Deliveries.{Claim, ClaimResponse}

  alias Oceanconnect.Accounts

  def generate(claim_response = %ClaimResponse{}),
    do: claim_response |> Deliveries.fully_loaded() |> emails()

  defp emails(
         claim_response = %{
           claim: claim = %Claim{buyer: buyer = %Company{id: company_id}, supplier: supplier},
           author: %{company_id: company_id} = author
         }
       ) do
    recipients = Accounts.users_for_companies([supplier])

    author_name = Accounts.User.full_name(author)

    if claim_contact_id = most_recent_supplier_contact(claim, recipients) do
      claim_contact = recipients |> Enum.filter(&(&1.id == claim_contact_id)) |> List.first()

      base_email(claim_contact)
      |> subject(
        "#{author_name} from #{buyer.name} added a response to the claim against #{supplier.name}"
      )
      |> render("supplier_claim_response_created.html",
        user: claim_contact,
        claim: claim,
        claim_response: claim_response,
        author_name: author_name,
        supplier: supplier,
        buyer: buyer
      )
      |> List.wrap()
    else
      Enum.map(recipients, fn recipient ->
        base_email(recipient)
        |> subject(
          "#{author_name} from #{buyer.name} added a response to the claim against #{
            supplier.name
          }"
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
  end

  defp emails(
         claim_response = %{
           claim: claim = %{buyer: buyer, supplier: supplier},
           author: author
         }
       ) do
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

  defp most_recent_supplier_contact(claim, recipients) do
    claim
    |> Deliveries.get_claim_responses_for_claim()
    |> Enum.sort_by(&DateTime.to_unix(&1.inserted_at), &>=/2)
    |> Enum.map(& &1.author_id)
    |> MapSet.new()
    |> MapSet.intersection(recipients |> Enum.map(& &1.id) |> MapSet.new())
    |> MapSet.to_list()
    |> List.first()
  end
end
