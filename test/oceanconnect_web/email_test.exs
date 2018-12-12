defmodule OceanconnectWeb.EmailTest do
  use Oceanconnect.DataCase

  alias OceanconnectWeb.Email
  alias Oceanconnect.Accounts
  alias Oceanconnect.Auctions

  setup do
    credit_company = insert(:company, name: "Ocean Connect Marine", is_broker: true)
    buyer_company = insert(:company, is_supplier: false, broker_entity: credit_company)
    buyers = [insert(:user, %{company: buyer_company}), insert(:user, %{company: buyer_company})]
    barge1 = insert(:barge)
    barge2 = insert(:barge)

    supplier_companies = [
      insert(:company, is_supplier: true),
      insert(:company, is_supplier: true)
    ]

    non_participating_suppliers =
      for company <- supplier_companies, do: insert(:user, company: company)

    non_participating_buyers = insert_list(2, :user, company: buyer_company)

    Enum.each(supplier_companies, fn supplier_company ->
      insert(:user, company: supplier_company)
    end)

    winning_supplier_company = Enum.at(Enum.take_random(supplier_companies, 1), 0)

    vessel = insert(:vessel)
    fuel = insert(:fuel)
    fuel2 = insert(:fuel)

    auction =
      insert(
        :auction,
        buyer: buyer_company,
        suppliers: supplier_companies,
        auction_vessel_fuels: [
          build(:vessel_fuel, vessel: vessel, fuel: fuel, quantity: 200),
          build(:vessel_fuel, vessel: vessel, fuel: fuel2, quantity: 200)
        ]
      )
      |> Auctions.fully_loaded()

    vessel_fuels = auction.auction_vessel_fuels

    approved_barges = [
      insert(:auction_barge, auction: auction, barge: barge1, supplier: hd(supplier_companies)),
      insert(:auction_barge,
        auction: auction,
        barge: barge2,
        supplier: List.last(supplier_companies)
      )
    ]

    suppliers = Accounts.users_for_companies(supplier_companies)
    winning_suppliers = Accounts.users_for_companies([winning_supplier_company])

    solution_bids = [
      create_bid(
        200.00,
        nil,
        hd(supplier_companies).id,
        hd(auction.auction_vessel_fuels).fuel.id,
        auction,
        true
      ),
      create_bid(
        220.00,
        nil,
        List.last(supplier_companies).id,
        List.last(auction.auction_vessel_fuels).fuel.id,
        auction,
        false
      )
    ]

    %Auctions.AuctionStore.AuctionState{product_bids: product_bids} =
      Auctions.AuctionStore.AuctionState.from_auction(auction)

    winning_solution = Auctions.Solution.from_bids(solution_bids, product_bids, auction)

    {:ok,
     %{
       non_participating_suppliers: non_participating_suppliers,
       non_participating_buyers: non_participating_buyers,
       suppliers: suppliers,
       credit_company: credit_company,
       buyer_company: buyer_company,
       buyers: buyers,
       auction: auction,
       vessel_fuels: vessel_fuels,
       vessel: vessel,
       fuel: fuel,
       winning_solution: winning_solution,
       winning_suppliers: winning_suppliers,
       approved_barges: approved_barges
     }}
  end

  describe "emails" do
    test "auction invitation email builds for suppliers", %{
      suppliers: suppliers,
      auction: auction,
      buyer_company: buyer_company
    } do
      vessel_name_list =
        auction.vessels
        |> Enum.map(& &1.name)
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
      vessel_name_list =
        auction.vessels
        |> Enum.map(& &1.name)
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

    test "auction completion email builds for winning suppliers and buyer who participated in the auction",
         %{
           buyers: buyers,
           auction: auction,
           winning_solution: winning_solution,
           approved_barges: approved_barges,
           suppliers: suppliers,
           non_participating_suppliers: non_participating_suppliers,
           non_participating_buyers: non_participating_buyers
         } do
      non_participating_suppliers_emails = non_participating_suppliers |> Enum.map(& &1.email)
      non_participating_buyers_emails = non_participating_buyers |> Enum.map(& &1.email)

      vessel_name_list =
        auction.vessels
        |> Enum.map(& &1.name)
        |> Enum.join(", ")

      active_users = buyers ++ suppliers

      %{supplier_emails: winning_supplier_emails, buyer_emails: buyer_emails} =
        Email.auction_closed(
          winning_solution.bids,
          approved_barges,
          auction,
          active_users
        )

      sent_supplier_emails = Enum.map(winning_supplier_emails, & &1.to)
      sent_buyer_emails = Enum.map(buyer_emails, & &1.to)

      refute Enum.any?(non_participating_suppliers_emails, &(&1 in sent_supplier_emails))
      refute Enum.any?(non_participating_buyers_emails, &(&1 in sent_buyer_emails))

      for supplier_email <- winning_supplier_emails do
        assert supplier_email.subject ==
                 "You have won Auction #{auction.id} for #{vessel_name_list} at #{
                   auction.port.name
                 }!"

        assert supplier_email.html_body =~ Integer.to_string(auction.id)
        assert supplier_email.html_body =~ vessel_name_list
        assert supplier_email.html_body =~ vessel_name_list
      end

      for buyer <- buyers do
        assert Enum.any?(buyer_emails, fn buyer_email -> buyer_email.to.id == buyer.id end)

        assert Enum.any?(buyer_emails, fn buyer_email ->
                 buyer_email.html_body =~ Accounts.User.full_name(buyer)
               end)

        assert Enum.any?(buyer_emails, fn buyer_email ->
                 buyer_email.html_body =~ "Physical Supplier"
               end)
      end
    end

    test "auction cancellation email builds for all participants", %{
      suppliers: suppliers,
      buyer_company: buyer_company,
      buyers: buyers,
      auction: auction
    } do
      vessel_name_list =
        auction.vessels
        |> Enum.map(& &1.name)
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
