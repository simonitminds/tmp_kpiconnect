defmodule Oceanconnect.Notifications.Emails.ClaimResponseCreatedTest do
  use Oceanconnect.DataCase
  alias Oceanconnect.Notifications.Emails
  alias Oceanconnect.Auctions

  setup do
    buyer_company = insert(:company, name: "The Buyer Company")
    buyer = insert(:user, company: buyer_company, first_name: "Buyer", last_name: "Dude")
    buyer2 = insert(:user, company: buyer_company, first_name: "Other", last_name: "Buyer")

    supplier_company = insert(:company, is_supplier: true, name: "Some Supplier Company")
    other_supplier_company = insert(:company, is_supplier: true)

    supplier_user = insert(:user, company: supplier_company, first_name: "Some", last_name: "Guy")

    other_supplier_user =
      insert(:user, company: supplier_company, first_name: "Another", last_name: "User")

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
       buyer2: buyer2,
       buyer_company: buyer_company,
       fixture: fixture,
       other_supplier_user: other_supplier_user,
       supplier_company: supplier_company,
       supplier_user: supplier_user
     }}
  end

  describe "claim responses received by buyer" do
    test "generate/1 creates email to all the buyer users for a supplier claim response", %{
      claim_response: claim_response
    } do
      emails = Emails.ClaimResponseCreated.generate(claim_response)

      assert 2 == length(emails)

      for email <- emails do
        assert email.subject ==
                 "Some Guy from Some Supplier Company responded to the claim made by The Buyer Company"

        assert email.html_body =~ "I hate you"
      end
    end

    test "generate/1 creates email for responding buyer user only", %{
      buyer: buyer,
      claim: claim,
      supplier_user: supplier_user
    } do
      insert(:claim_response, author: buyer, claim: claim, content: "WTF buddy")

      supplier_second_response =
        insert(:claim_response, author: supplier_user, claim: claim, content: "It is what it is")

      emails = Emails.ClaimResponseCreated.generate(supplier_second_response)

      for email <- emails do
        assert email.subject ==
                 "Some Guy from Some Supplier Company responded to the claim made by The Buyer Company"

        assert email.to.id == buyer.id
        assert email.html_body =~ "It is what it is"
      end
    end

    test "generate/1 sends email to most recent responding buyer user only", %{
      buyer: buyer,
      claim: claim,
      other_supplier_user: other_supplier_user,
      supplier_user: supplier_user
    } do
      insert(:claim_response, author: buyer, claim: claim, content: "WTF buddy")
      insert(:claim_response, author: supplier_user, claim: claim, content: "It is what it is")

      :timer.sleep(1_000)

      other_supplier_response =
        insert(:claim_response, author: other_supplier_user, claim: claim, content: "Yeah, ditto!")

      emails = Emails.ClaimResponseCreated.generate(other_supplier_response)

      for email <- emails do
        assert email.subject ==
                 "Another User from Some Supplier Company responded to the claim made by The Buyer Company"

        assert email.to.id == buyer.id
        assert email.html_body =~ "Yeah, ditto!"
      end
    end

    test "generate/1 sends email to most recent responding buyer user of any claim", %{
      auction: auction,
      buyer: buyer,
      buyer2: buyer2,
      claim: claim,
      fixture: fixture,
      supplier_user: supplier_user
    } do
      insert(:claim_response, author: buyer, claim: claim, content: "WTF buddy")

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
      insert(:claim_response, author: buyer2, claim: new_claim, content: "Quality is jacked!")

      supplier_second_response =
        insert(:claim_response, author: supplier_user, claim: claim, content: "It is what it is")

      emails = Emails.ClaimResponseCreated.generate(supplier_second_response)

      for email <- emails do
        assert email.subject ==
                 "Some Guy from Some Supplier Company responded to the claim made by The Buyer Company"

        assert email.to.id == buyer2.id
        assert email.html_body =~ "It is what it is"
      end
    end
  end

  describe "claim responses received by supplier" do
    test "generate/1 creates email for responding supplier user only", %{
      buyer: buyer,
      claim: claim,
      supplier_user: supplier_user
    } do
      buyer_response = insert(:claim_response, author: buyer, claim: claim, content: "WTF buddy")
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
      insert(:claim_response, author: other_supplier_user, claim: claim, content: "Yeah, ditto!")

      buyer_response = insert(:claim_response, author: buyer, claim: claim, content: "WTF buddy")
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

      insert(:claim_response, author: other_supplier_user, claim: new_claim, content: "It wrong!")
      buyer_response = insert(:claim_response, author: buyer, claim: claim, content: "WTF buddy")
      emails = Emails.ClaimResponseCreated.generate(buyer_response)

      for email <- emails do
        assert email.subject ==
                 "Buyer Dude from The Buyer Company added a response to the claim against Some Supplier Company"

        assert email.to.id == other_supplier_user.id
        assert email.html_body =~ "WTF buddy"
      end
    end
  end
end
