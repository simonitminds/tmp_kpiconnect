defmodule Oceanconnect.Notifications.Emails.DeliveredCOQReminderTest do
  use Oceanconnect.DataCase
  alias Oceanconnect.Notifications.Emails.DeliveredCOQReminder
  alias Oceanconnect.Accounts
  alias Oceanconnect.Auctions

  alias Oceanconnect.Auctions.{
    AuctionStore.AuctionState,
    Solution,
    AuctionStore.TermAuctionState,
    TermAuction
  }

  describe "Spot Auctions" do
    setup do
      credit_company = insert(:company, name: "Ocean Connect Marine", is_broker: true)
      broker = insert(:company)
      buyer_company = insert(:company, broker_entity: broker)
      buyers = insert_list(2, :user, company: buyer_company)
      supplier_companies = [sc1, sc2, sc3] = insert_list(3, :company, is_supplier: true)
      Enum.each(supplier_companies, &insert(:user, company: &1))
      suppliers = Accounts.users_for_companies(supplier_companies)

      winning_suppliers = Accounts.users_for_companies([sc1, sc3])

      [vessel1, vessel2] = insert_list(2, :vessel)
      [fuel1, fuel2, fuel3] = insert_list(3, :fuel)

      auction =
        :auction
        |> insert(
          buyer: buyer_company,
          suppliers: supplier_companies,
          auction_vessel_fuels: [
            build(:vessel_fuel, vessel: vessel1, fuel: fuel1, quantity: 200),
            build(:vessel_fuel, vessel: vessel2, fuel: fuel2, quantity: 200),
            build(:vessel_fuel, vessel: vessel2, fuel: fuel3, quantity: 400)
          ]
        )

      [avf1, avf2, avf3] = auction.auction_vessel_fuels

      solution_bids = [
        bid1 =
          create_bid(
            200.00,
            nil,
            sc1.id,
            "#{avf1.id}",
            auction,
            true
          ),
        bid2 =
          create_bid(
            220.00,
            nil,
            sc3.id,
            "#{avf2.id}",
            auction,
            false
          ),
        bid3 =
          create_bid(
            250.00,
            nil,
            sc3.id,
            "#{avf3.id}",
            auction,
            false
          )
      ]

      auction_state =
        %AuctionState{product_bids: product_bids} = Auctions.get_auction_state!(auction)

      winning_solution = Solution.from_bids(solution_bids, product_bids, auction)

      auction_state =
        auction_state
        |> Map.merge(%{winning_solution: winning_solution})

      {:ok,
       %{
         auction: auction,
         auction_state: auction_state,
         buyers: buyers,
         fuels: [fuel1, fuel2, fuel3],
         suppliers: suppliers,
         supplier_companies: supplier_companies,
         winning_solution: winning_solution,
         winning_suppliers: winning_suppliers
       }}
    end

    test "delivered coq reminder email builds for winning suppliers",
         %{
           auction: auction,
           fuels: [fuel1, fuel2, fuel3],
           supplier_companies: [sc1, _sc2, sc3],
           winning_solution: winning_solution,
           winning_suppliers: winning_suppliers
         } do
      emails = DeliveredCOQReminder.generate(auction.id, winning_solution)
      sent_to_ids = Enum.map(emails, fn email -> email.to.id end)
      winning_supplier_ids = Enum.map(winning_suppliers, & &1.id)

      assert Enum.all?(winning_supplier_ids, &(&1 in sent_to_ids))

      sent_emails = Enum.map(emails, & &1.to)

      for email <- emails do
        assert email.subject ==
                 "Please upload fuel certificate(s) for Auction #{auction.id}."

        assert email.html_body =~
                 "Please upload a Certificate of Quality on Auction #{auction.id}"

        if email.to.company_id == sc1.id do
          assert email.html_body =~ fuel1.name
          Enum.all?([fuel2, fuel3], &refute(email.html_body =~ &1.name))
        else
          Enum.all?([fuel2, fuel3], &assert(email.html_body =~ &1.name))
          refute email.html_body =~ fuel1.name
        end
      end
    end
  end

  describe "Term Auction" do
    setup do
      credit_company = insert(:company, name: "Ocean Connect Marine", is_broker: true)
      broker = insert(:company)
      buyer_company = insert(:company, broker_entity: broker)
      buyers = insert_list(2, :user, company: buyer_company)

      supplier_companies = insert_list(2, :company, is_supplier: true)
      Enum.each(supplier_companies, &insert(:user, company: &1))
      suppliers = Accounts.users_for_companies(supplier_companies)

      [winning_supplier_company] = Enum.take_random(supplier_companies, 1)
      winning_suppliers = Accounts.users_for_companies([winning_supplier_company])

      barges = insert_list(2, :barge)
      [vessel1, vessel2] = insert_list(2, :vessel)
      [fuel1, fuel2] = insert_list(2, :fuel)
      [barge1, barge2] = insert_list(2, :barge)

      auction =
        insert(:term_auction,
          buyer: buyer_company,
          suppliers: supplier_companies
        )

      solution_bids = [
        bid1 =
          create_bid(
            200.00,
            nil,
            hd(supplier_companies).id,
            "#{auction.fuel.id}",
            auction,
            true
          ),
        bid2 =
          create_bid(
            220.00,
            nil,
            List.last(supplier_companies).id,
            "#{auction.fuel.id}",
            auction,
            false
          )
      ]

      auction_state =
        %TermAuctionState{product_bids: product_bids} = Auctions.get_auction_state!(auction)

      # THIS IS SO THAT EVENTS ARE GENERATED CONTAINING THE PARTICIPANTS IDS
      created_event = Oceanconnect.Auctions.AuctionEvent.auction_created(auction, hd(buyers))

      bid_event1 =
        Oceanconnect.Auctions.AuctionEvent.bid_placed(
          bid1,
          hd(Map.values(product_bids)),
          hd(suppliers)
        )

      bid_event2 =
        Oceanconnect.Auctions.AuctionEvent.bid_placed(
          bid2,
          hd(Map.values(product_bids)),
          tl(suppliers)
        )

      [created_event, bid_event1, bid_event2]
      |> Enum.map(fn event -> Oceanconnect.Auctions.AuctionEventStore.persist(event) end)

      winning_solution = Solution.from_bids(solution_bids, product_bids, auction)

      auction_state =
        auction_state
        |> Map.merge(%{winning_solution: winning_solution})

      {:ok,
       %{
         auction_state: auction_state,
         buyers: buyers,
         suppliers: suppliers,
         supplier_companies: supplier_companies,
         winning_suppliers: winning_suppliers,
         vessels: [vessel1, vessel2]
       }}
    end

    test "delivered coq reminder email builds for winning supplier",
         %{
           auction_state: auction_state,
           winning_suppliers: winning_suppliers,
           buyers: buyers,
           vessels: [vessel1, vessel2]
         } do
      emails = DeliveredCOQReminder.generate(auction_state)
      sent_to_ids = Enum.map(emails, fn email -> email.to.id end)
      winning_supplier_ids = Enum.map(winning_suppliers, & &1.id)
      buyer_ids = Enum.map(buyers, & &1.id)
      auction = Auctions.get_auction!(auction_state.auction_id)

      assert Enum.all?(winning_supplier_ids, &(&1 in sent_to_ids))

      # Only 1 buyer participated by generating events in the system
      assert Enum.any?(buyer_ids, &(&1 in sent_to_ids))

      sent_emails = Enum.map(emails, & &1.to)

      {supplier_emails, buyer_emails} = Enum.split_with(emails, &(&1.assigns.is_buyer == false))

      for supplier_email <- supplier_emails do
        assert supplier_email.subject ==
                 "You have won Auction #{auction.id} at #{auction.port.name}!"

        assert supplier_email.html_body =~ Integer.to_string(auction.id)
      end

      for buyer <- buyers do
        assert Enum.any?(buyer_emails, fn buyer_email ->
                 buyer_email.html_body =~ "Physical Supplier"
               end)
      end
    end
  end
end
