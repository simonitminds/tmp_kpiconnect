defmodule Oceanconnect.Notifications.Emails.ClaimResponseCreatedTest do
  use Oceanconnect.DataCase
  alias Oceanconnect.Notifications.Emails
  alias Oceanconnect.Auctions

  setup do
    buyer_company = insert(:company, name: "The Buyer Company")
    buyer = insert(:user, company: buyer_company, first_name: "Buyer", last_name: "Dude")

    supplier_company = insert(:company, is_supplier: true, name: "Some Supplier Company")
    other_supplier_company = insert(:company, is_supplier: true)

    supplier_user = insert(:user, company: supplier_company, first_name: "Some", last_name: "Guy")

    other_supplier_user = insert(:user, company: supplier_company)

    auction =
      insert(
        :auction,
        buyer: buyer_company,
        suppliers: [supplier_company, other_supplier_company]
      )
      |> Auctions.fully_loaded()

    {:ok, fixtures} =
      close_auction!(auction)
      |> Auctions.create_fixtures_from_state()

    fixture =
      hd(fixtures)
      |> Oceanconnect.Repo.preload([:vessel, :fuel, :supplier])

    claim =
      insert(
        :claim,
        type: "quantity",
        fixture: fixture,
        quantity_missing: 100,
        price_per_unit: 100,
        additional_information: "You shorted me you cheapskate!",
        auction: auction,
        receiving_vessel: fixture.vessel,
        delivered_fuel: fixture.fuel,
        supplier: fixture.supplier,
        buyer: buyer_company,
        notice_recipient_type: "supplier",
        notice_recipient: fixture.supplier
      )

    claim_response =
      insert(:claim_response, author: supplier_user, claim: claim, content: "I hate you")

    {:ok,
     %{
       auction: auction,
       claim: claim,
       claim_response: claim_response,
       buyer: buyer,
       buyer_company: buyer_company,
       fixture: fixture,
       other_supplier_user: other_supplier_user,
       supplier_company: supplier_company,
       supplier_user: supplier_user
     }}
  end

  test "generate/1 creates email to the buyer for a supplier claim response", %{
    buyer: buyer,
    claim_response: claim_response
  } do
    emails = Emails.ClaimResponseCreated.generate(claim_response)

    for email <- emails do
      assert email.subject ==
               "Some Guy from Some Supplier Company responded to the claim made by The Buyer Company"

      assert email.to.id == buyer.id
      assert email.html_body =~ "I hate you"
    end
  end

  test "generate/1 creates email for responding supplier user only", %{
    buyer: buyer,
    claim: claim,
    supplier_user: supplier_user
  } do
    buyer_response = insert(:claim_response, claim: claim, author: buyer, content: "WTF buddy")
    emails = Emails.ClaimResponseCreated.generate(buyer_response)

    for email <- emails do
      assert email.subject ==
               "Buyer Dude from The Buyer Company added a response to the claim against Some Supplier Company"

      assert email.to.id == supplier_user.id
      assert email.html_body =~ "WTF buddy"
    end
  end

  test "generate/1 sends email to most recent responding supplier user only", %{
    buyer: buyer,
    claim: claim,
    other_supplier_user: other_supplier_user
  } do
    :timer.sleep(1_000)
    insert(:claim_response, claim: claim, author: other_supplier_user, content: "Yeah, ditto!")

    buyer_response = insert(:claim_response, claim: claim, author: buyer, content: "WTF buddy")
    emails = Emails.ClaimResponseCreated.generate(buyer_response)

    for email <- emails do
      assert email.subject ==
               "Buyer Dude from The Buyer Company added a response to the claim against Some Supplier Company"

      assert email.to.id == other_supplier_user.id
      assert email.html_body =~ "WTF buddy"
    end
  end

  test "generate/1 sends email to most recent responding supplier user of any claim", %{
    auction: auction,
    buyer: buyer,
    claim: claim,
    fixture: fixture,
    other_supplier_user: other_supplier_user
  } do
    new_claim =
      insert(
        :claim,
        type: "quality",
        fixture: fixture,
        additional_information: "Your fuel sucked too!",
        auction: auction,
        receiving_vessel: fixture.vessel,
        delivered_fuel: fixture.fuel,
        supplier: fixture.supplier,
        notice_recipient_type: "supplier",
        notice_recipient: fixture.supplier
      )

    :timer.sleep(1_000)

    insert(:claim_response, claim: new_claim, author: other_supplier_user, content: "It wrong!")
    buyer_response = insert(:claim_response, claim: claim, author: buyer, content: "WTF buddy")
    emails = Emails.ClaimResponseCreated.generate(buyer_response)

    for email <- emails do
      assert email.subject ==
               "Buyer Dude from The Buyer Company added a response to the claim against Some Supplier Company"

      assert email.to.id == other_supplier_user.id
      assert email.html_body =~ "WTF buddy"
    end
  end
end
