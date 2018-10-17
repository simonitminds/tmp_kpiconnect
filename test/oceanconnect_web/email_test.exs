defmodule OceanconnectWeb.EmailTest do
  use Oceanconnect.DataCase

  alias OceanconnectWeb.Email
  alias Oceanconnect.Accounts
  alias Oceanconnect.Auctions

  setup do
    credit_company = insert(:company, name: "Ocean Connect Marine")
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

    vessel = insert(:vessel)
    fuel = insert(:fuel)

    auction =
      insert(:auction, buyer: buyer_company, suppliers: supplier_companies, auction_vessel_fuels: [build(:vessel_fuel, vessel: vessel, fuel: fuel, quantity: 200)])
      |> Auctions.fully_loaded()
    vessel_fuels = auction.auction_vessel_fuels

    winning_bid_amount = 100.00

    suppliers = Accounts.users_for_companies(supplier_companies)
    winning_suppliers = Accounts.users_for_companies([winning_supplier_company])

    {:ok,
     %{
       suppliers: suppliers,
       credit_company: credit_company,
       buyer_company: buyer_company,
       buyers: buyers,
       auction: auction,
       vessel_fuels: vessel_fuels,
       vessel: vessel,
       fuel: fuel,
       winning_supplier_company: winning_supplier_company,
       winning_suppliers: winning_suppliers,
       winning_bid_amount: winning_bid_amount
     }}
  end

  describe "emails" do
    test "auction invitation email builds for suppliers", %{
      suppliers: suppliers,
      auction: auction,
      buyer_company: buyer_company
    } do
      vessel_name_list = auction.vessels
      |> Enum.map(&(&1.name))
      |> Enum.join(", ")

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
                 "You have been invited to Auction #{auction.id} for #{vessel_name_list} at #{
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
      vessel_name_list = auction.vessels
      |> Enum.map(&(&1.name))
      |> Enum.join(", ")

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
                 "Auction #{auction.id} for #{vessel_name_list} at #{auction.port.name} is starting soon."

        assert supplier_email.html_body =~ buyer_company.name
        assert supplier_email.html_body =~ Integer.to_string(auction.id)
      end

      for buyer_email <- buyer_emails do
        assert buyer_email.subject ==
                 "Auction #{auction.id} for #{vessel_name_list} at #{auction.port.name} is starting soon."

        assert buyer_email.html_body =~ buyer_company.name
        assert buyer_email.html_body =~ Integer.to_string(auction.id)
      end
    end

    test "auction completion email builds for winning supplier and buyer", %{
      buyer_company: buyer_company,
      winning_supplier_company: winning_supplier_company,
      buyers: buyers,
      auction: auction,
      winning_suppliers: winning_suppliers,
      winning_bid_amount: winning_bid_amount
    } do
      is_traded_bid = false
      vessel_name_list = auction.vessels
      |> Enum.map(&(&1.name))
      |> Enum.join(", ")

      %{supplier_emails: winning_supplier_emails, buyer_emails: buyer_emails} =
        Email.auction_closed(
          winning_bid_amount,
          winning_supplier_company,
          auction,
          is_traded_bid
        )

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
                 "You have won Auction #{auction.id} for #{vessel_name_list} at #{
                   auction.port.name
                 }!"

        assert supplier_email.html_body =~ winning_supplier_company.name
        assert supplier_email.html_body =~ buyer_company.name
        assert supplier_email.html_body =~ buyer_company.contact_name
        assert supplier_email.html_body =~ Integer.to_string(auction.id)
        assert supplier_email.html_body =~ vessel_name_list
        assert supplier_email.html_body =~
                 "$#{:erlang.float_to_binary(winning_bid_amount, decimals: 2)}"
        assert supplier_email.html_body =~ vessel_name_list
      end

      for buyer <- buyers do
        assert Enum.any?(buyer_emails, fn buyer_email -> buyer_email.to.id == buyer.id end)

        assert Enum.any?(buyer_emails, fn buyer_email ->
                 buyer_email.html_body =~ Accounts.User.full_name(buyer)
               end)
      end

      for buyer_email <- buyer_emails do
        assert buyer_email.subject ==
                 "Auction #{auction.id} for #{vessel_name_list} at #{auction.port.name} has closed."

        assert buyer_email.html_body =~ winning_supplier_company.name
        assert buyer_email.html_body =~ winning_supplier_company.contact_name
        assert buyer_email.html_body =~ buyer_company.name
        assert buyer_email.html_body =~ buyer_company.contact_name
        assert buyer_email.html_body =~ Integer.to_string(auction.id)
        assert buyer_email.html_body =~ vessel_name_list
      end
    end

    test "auction completion with traded bid builds for winning supplier and buyer", %{
      buyer_company: buyer_company,
      credit_company: oceanconnect,
      winning_supplier_company: winning_supplier_company,
      buyers: buyers,
      auction: auction,
      winning_suppliers: winning_suppliers,
      winning_bid_amount: winning_bid_amount
    } do
      is_traded_bid = true
      vessel_name_list = auction.vessels
      |> Enum.map(&(&1.name))
      |> Enum.join(", ")

      %{supplier_emails: winning_supplier_emails, buyer_emails: buyer_emails} =
        Email.auction_closed(
          winning_bid_amount,
          winning_supplier_company,
          auction,
          is_traded_bid
        )

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
                 "You have won Auction #{auction.id} for #{vessel_name_list} at #{
                   auction.port.name
                 }!"

        assert supplier_email.html_body =~ winning_supplier_company.name
        assert supplier_email.html_body =~ oceanconnect.name
        assert supplier_email.html_body =~ oceanconnect.contact_name
        assert supplier_email.html_body =~ Integer.to_string(auction.id)
        assert supplier_email.html_body =~ vessel_name_list

        assert supplier_email.html_body =~
                 "$#{:erlang.float_to_binary(winning_bid_amount, decimals: 2)}"
      end

      for buyer <- buyers do
        assert Enum.any?(buyer_emails, fn buyer_email -> buyer_email.to.id == buyer.id end)

        assert Enum.any?(buyer_emails, fn buyer_email ->
                 buyer_email.html_body =~ Accounts.User.full_name(buyer)
               end)
      end

      for buyer_email <- buyer_emails do
        assert buyer_email.subject ==
                 "Auction #{auction.id} for #{vessel_name_list} at #{auction.port.name} has closed."

        assert buyer_email.html_body =~ oceanconnect.name
        assert buyer_email.html_body =~ oceanconnect.contact_name
        assert buyer_email.html_body =~ buyer_company.name
        assert buyer_email.html_body =~ buyer_company.contact_name
        assert buyer_email.html_body =~ Integer.to_string(auction.id)
        assert buyer_email.html_body =~ vessel_name_list
      end
    end

    test "auction cancellation email builds for all participants", %{
      suppliers: suppliers,
      buyer_company: buyer_company,
      buyers: buyers,
      auction: auction
    } do
      vessel_name_list = auction.vessels
      |> Enum.map(&(&1.name))
      |> Enum.join(", ")

      supplier_emails = Email.auction_canceled(auction).supplier_emails

      for supplier <- suppliers do
        Enum.any?(supplier_emails, fn supplier_email -> supplier_email.to.id == supplier.id end)

        Enum.any?(supplier_emails, fn supplier_email ->
          supplier_email.html_body =~ Accounts.User.full_name(supplier)
        end)
      end

      for supplier_email <- supplier_emails do
        assert supplier_email.subject ==
                 "Auction #{auction.id} for #{vessel_name_list} at #{auction.port.name} cancelled."

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
                 "You have canceled Auction #{auction.id} for #{vessel_name_list} at #{
                   auction.port.name
                 }."

        assert buyer_email.html_body =~ Integer.to_string(auction.id)
        assert buyer_email.html_body =~ buyer_company.name
      end
    end
  end
end
