defmodule OceanconnectWeb.EmailTest do
  use Oceanconnect.DataCase

  alias OceanconnectWeb.Email
  alias Oceanconnect.Accounts
  alias Oceanconnect.Auctions

  setup do
    buyer_company = insert(:company, is_supplier: false)
    buyers = [insert(:user, %{company: buyer_company}), insert(:user, %{company: buyer_company})]

    supplier_companies = [
      insert(:company, is_supplier: true),
      insert(:company, is_supplier: true)
    ]

    winning_supplier_company = Enum.at(Enum.take_random(supplier_companies, 1), 0)

    Enum.each(supplier_companies, fn supplier_company ->
      insert(:user, %{company: supplier_company})
    end)

    auction =
      insert(:auction, buyer: buyer_company, suppliers: supplier_companies)
      |> Auctions.fully_loaded()

    suppliers = Accounts.users_for_companies(supplier_companies)
    winning_suppliers = Accounts.users_for_companies([winning_supplier_company])

    {:ok,
     %{
       suppliers: suppliers,
       buyer_company: buyer_company,
       buyers: buyers,
       auction: auction,
       winning_supplier_company: winning_supplier_company,
       winning_suppliers: winning_suppliers
     }}
  end

  describe "emails" do
    test "auction invitation email builds for suppliers", %{
      suppliers: suppliers,
      auction: auction,
      buyer_company: buyer_company
    } do
      supplier_emails = Email.auction_invitation(auction)

      for supplier <- suppliers do
        assert Enum.any?(supplier_emails, fn supplier_email ->
                 supplier_email.to.id == supplier.id
               end)

        assert Enum.any?(supplier_emails, fn supplier_email ->
                 supplier_email.html_body =~ Accounts.User.full_name(supplier)
               end)
      end

      for supplier_email <- supplier_emails do
        assert supplier_email.subject ==
                 "You have been invited to Auction #{auction.id} for #{auction.vessel.name} at #{
                   auction.port.name
                 }"

        assert supplier_email.html_body =~ buyer_company.name
        assert supplier_email.html_body =~ Integer.to_string(auction.id)
      end
    end

    test "auction invitation email does not build for buyers", %{buyers: buyers, auction: auction} do
      emails = Email.auction_invitation(auction)
      for buyer <- buyers, do: refute(Enum.any?(emails, fn email -> email.to.id == buyer.id end))
    end

    test "auction starting soon email builds for all participants", %{
      suppliers: suppliers,
      buyers: buyers,
      auction: auction,
      buyer_company: buyer_company
    } do
      %{supplier_emails: supplier_emails, buyer_emails: buyer_emails} =
        Email.auction_starting_soon(auction)

      for supplier <- suppliers,
          do:
            assert(
              Enum.any?(supplier_emails, fn supplier_email ->
                supplier_email.to.id == supplier.id
              end)
            )

      for buyer <- buyers,
          do: assert(Enum.any?(buyer_emails, fn buyer_email -> buyer_email.to.id == buyer.id end))

      for supplier_email <- supplier_emails do
        assert supplier_email.subject ==
                 "Auction #{auction.id} for #{auction.vessel.name} at #{auction.port.name} is starting soon."

        assert supplier_email.html_body =~ buyer_company.name
        assert supplier_email.html_body =~ Integer.to_string(auction.id)
      end

      for buyer_email <- buyer_emails do
        assert buyer_email.subject ==
                 "Auction #{auction.id} for #{auction.vessel.name} at #{auction.port.name} is starting soon."

        assert buyer_email.html_body =~ buyer_company.name
        assert buyer_email.html_body =~ Integer.to_string(auction.id)
      end
    end

    test "auction completion email builds for winning supplier and buyer", %{
      buyer_company: buyer_company,
      winning_supplier_company: winning_supplier_company,
      buyers: buyers,
      auction: auction,
      winning_suppliers: winning_suppliers
    } do
      %{supplier_emails: winning_supplier_emails, buyer_emails: buyer_emails} =
        Email.auction_closed(100, 20000, winning_supplier_company, auction)

      for supplier <- winning_suppliers do
        assert Enum.any?(winning_supplier_emails, fn supplier_email ->
                 supplier_email.to.id == supplier.id
               end)

        assert Enum.any?(winning_supplier_emails, fn supplier_email ->
                 supplier_email.html_body =~ Accounts.User.full_name(supplier)
               end)
      end

      for supplier_email <- winning_supplier_emails do
        assert supplier_email.subject ==
                 "You have won Auction #{auction.id} for #{auction.vessel.name} at #{
                   auction.port.name
                 }!"

        assert supplier_email.html_body =~ winning_supplier_company.name
        assert supplier_email.html_body =~ buyer_company.name
        assert supplier_email.html_body =~ buyer_company.contact_name
        assert supplier_email.html_body =~ Integer.to_string(auction.id)
        assert supplier_email.html_body =~ auction.vessel.name
      end

      for buyer <- buyers do
        assert Enum.any?(buyer_emails, fn buyer_email -> buyer_email.to.id == buyer.id end)

        assert Enum.any?(buyer_emails, fn buyer_email ->
                 buyer_email.html_body =~ Accounts.User.full_name(buyer)
               end)
      end

      for buyer_email <- buyer_emails do
        assert buyer_email.subject ==
                 "Auction #{auction.id} for #{auction.vessel.name} at #{auction.port.name} has closed."

        assert buyer_email.html_body =~ winning_supplier_company.name
        assert buyer_email.html_body =~ winning_supplier_company.contact_name
        assert buyer_email.html_body =~ buyer_company.name
        assert buyer_email.html_body =~ buyer_company.contact_name
        assert buyer_email.html_body =~ Integer.to_string(auction.id)
        assert buyer_email.html_body =~ auction.vessel.name
      end
    end

    test "auction cancellation email builds for all participants", %{
      suppliers: suppliers,
      buyer_company: buyer_company,
      buyers: buyers,
      auction: auction
    } do
      supplier_emails = Email.auction_canceled(auction).supplier_emails

      for supplier <- suppliers do
        Enum.any?(supplier_emails, fn supplier_email -> supplier_email.to.id == supplier.id end)

        Enum.any?(supplier_emails, fn supplier_email ->
          supplier_email.html_body =~ Accounts.User.full_name(supplier)
        end)
      end

      for supplier_email <- supplier_emails do
        assert supplier_email.subject ==
                 "Auction #{auction.id} for #{auction.vessel.name} at #{auction.port.name} cancelled."

        assert supplier_email.html_body =~ Integer.to_string(auction.id)
        assert supplier_email.html_body =~ buyer_company.name
      end

      buyer_emails = Email.auction_canceled(auction).buyer_emails

      for buyer <- buyers do
        assert Enum.any?(buyer_emails, fn buyer_email -> buyer_email.to.id == buyer.id end)

        assert Enum.any?(buyer_emails, fn buyer_email ->
                 buyer_email.html_body =~ Accounts.User.full_name(buyer)
               end)
      end

      for buyer_email <- buyer_emails do
        assert buyer_email.subject ==
                 "You have canceled Auction #{auction.id} for #{auction.vessel.name} at #{
                   auction.port.name
                 }."

        assert buyer_email.html_body =~ Integer.to_string(auction.id)
        assert buyer_email.html_body =~ buyer_company.name
      end
    end
  end
end
