defmodule Oceanconnect.Notifications.EmailNotificationStoreTest do
  use Oceanconnect.DataCase
  use Bamboo.Test, shared: true

  alias Oceanconnect.Notifications.{EmailNotificationStore, Emails}
  alias Oceanconnect.Auctions
  alias Oceanconnect.Accounts

  alias Oceanconnect.Auctions.{
    AuctionEvent,
    EventNotifier,
    NonEventNotifier,
    AuctionStore.AuctionState,
    Solution,
    AuctionsSupervisor,
    AuctionSupplierCOQ
  }

  setup do
    {:ok, pid} = Oceanconnect.Notifications.NotificationsSupervisor.start_link()

    port = insert(:port)
    port_name = port.name
    fuel = insert(:fuel)
    buyer_company = insert(:company)
    buyer = insert(:user, company: buyer_company)
    supplier_companies = insert_list(2, :company, is_supplier: true)
    suppliers = Enum.map(supplier_companies, &insert(:user, company: &1))

    [barge1, barge2] = insert_list(2, :barge)
    [winning_supplier_company] = Enum.take_random(supplier_companies, 1)
    winning_suppliers = Accounts.users_for_companies([winning_supplier_company])

    vessels = insert_list(2, :vessel)

    vessel_fuels = insert_list(2, :vessel_fuel, fuel: fuel)

    auction =
      insert(:auction,
        buyer: buyer_company,
        port: port,
        suppliers: supplier_companies,
        auction_vessel_fuels: vessel_fuels
      )

    draft_auction =
      insert(:draft_auction,
        buyer: buyer_company,
        port: port,
        suppliers: supplier_companies,
        auction_vessel_fuels: vessel_fuels,
        scheduled_start: nil
      )

    solution_bids = [
      bid1 =
        create_bid(
          200.00,
          nil,
          hd(supplier_companies).id,
          "#{hd(auction.auction_vessel_fuels).id}",
          auction,
          true
        ),
      bid2 =
        create_bid(
          220.00,
          nil,
          List.last(supplier_companies).id,
          "#{hd(auction.auction_vessel_fuels).id}",
          auction,
          false
        )
    ]

    auction =
      auction
      |> Auctions.fully_loaded()
      |> Map.put(:vessels, Enum.map(vessel_fuels, & &1.vessel))

    Oceanconnect.Auctions.AuctionsSupervisor.start_child(auction)
    EmailNotificationStore.init([])

    auction_state =
      %AuctionState{product_bids: product_bids} = Auctions.get_auction_state!(auction)

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
        List.last(suppliers)
      )

    winning_solution = Solution.from_bids(solution_bids, product_bids, auction)

    approved_barges = [
      insert(:auction_barge,
        auction: auction,
        barge: barge1,
        supplier: hd(supplier_companies),
        approval_status: "APPROVED"
      ),
      insert(:auction_barge,
        auction: auction,
        barge: barge2,
        supplier: List.last(supplier_companies),
        approval_status: "APPROVED"
      )
    ]

    completed_auction_state =
      auction_state
      |> Map.merge(%{winning_solution: winning_solution, submitted_barges: approved_barges})

    vessel_name_list =
      vessel_fuels
      |> Enum.map(& &1.vessel.name)
      |> Enum.join(", ")

    {:ok,
     %{
       auction: auction,
       draft_auction: draft_auction,
       vessel_name_list: vessel_name_list,
       port_name: port_name,
       buyer: buyer,
       completed_auction_state: completed_auction_state
     }}
  end

  describe "auction event notifications" do
    test "auction created event produces email", %{
      auction: auction,
      vessel_name_list: vessel_name_list,
      port_name: port_name
    } do
      auction_state = AuctionState.from_auction(auction)

      AuctionEvent.auction_created(auction, nil)
      |> EventNotifier.broadcast(auction_state)

      :timer.sleep(1000)

      emails = Emails.AuctionInvitation.generate(auction_state)

      for email <- emails do
        assert_email_delivered_with(
          subject:
            "You have been invited to Auction #{auction.id} for #{vessel_name_list} at #{
              port_name
            }"
        )
      end
    end

    test "auction transitioned from draft to pending event produces email", %{
      auction: auction,
      vessel_name_list: vessel_name_list,
      port_name: port_name
    } do
      auction_state = AuctionState.from_auction(auction)

      AuctionEvent.auction_transitioned_from_draft_to_pending(
        auction,
        auction_state
      )
      |> EventNotifier.broadcast(auction_state)

      :timer.sleep(2000)

      emails = Emails.AuctionInvitation.generate(auction_state)

      for email <- emails do
        assert_email_delivered_with(
          subject:
            "You have been invited to Auction #{auction.id} for #{vessel_name_list} at #{
              port_name
            }"
        )
      end
    end

    test "auction created event with a draft auction does not produce emails", %{
      draft_auction: auction,
      vessel_name_list: vessel_name_list,
      port_name: port_name
    } do
      auction =
        auction
        |> Auctions.fully_loaded()

      auction_state = AuctionState.from_auction(auction)

      AuctionEvent.auction_created(auction, nil)
      |> EventNotifier.broadcast(auction_state)

      :timer.sleep(2000)

      emails = Emails.AuctionInvitation.generate(auction_state)

      for email <- emails do
        refute_delivered_email(email)
      end
    end

    test "auction rescheduled event produces email", %{
      auction: auction,
      vessel_name_list: vessel_name_list,
      port_name: port_name,
      buyer: buyer
    } do
      auction_state = AuctionState.from_auction(auction)

      AuctionEvent.auction_rescheduled(auction, buyer)
      |> EventNotifier.broadcast(auction_state)

      :timer.sleep(2000)

      emails = Emails.AuctionRescheduled.generate(auction_state)

      for email <- emails do
        assert_receive({:delivered_email, email}, 100, Bamboo.Test.flunk_no_emails_received())
      end

      AuctionsSupervisor.stop_child(auction)
    end

    test "auction cancellation event produces email", %{
      auction: auction,
      vessel_name_list: vessel_name_list,
      port_name: port_name,
      buyer: buyer
    } do
      auction_state = AuctionState.from_auction(auction)

      AuctionEvent.auction_canceled(auction, DateTime.utc_now(), auction_state, buyer)
      |> EventNotifier.broadcast(auction_state)

      :timer.sleep(1000)

      emails = Emails.AuctionCanceled.generate(auction_state)
      buyer_emails = Enum.filter(emails, &(&1.to.id == buyer.id))
      supplier_emails = Enum.filter(emails, &(&1.to.id != buyer.id))

      for email <- buyer_emails do
        assert_receive({:delivered_email, email}, 100, Bamboo.Test.flunk_no_emails_received())
      end

      for email <- supplier_emails do
        assert_receive({:delivered_email, email}, 100, Bamboo.Test.flunk_no_emails_received())
      end

      AuctionsSupervisor.stop_child(auction)
    end

    test "auction completion event produces email", %{
      auction: auction,
      completed_auction_state: completed_auction_state,
      buyer: buyer
    } do
      AuctionEvent.auction_closed(auction, DateTime.utc_now(), completed_auction_state)
      |> EventNotifier.broadcast(completed_auction_state)

      emails = Emails.AuctionClosed.generate(completed_auction_state)

      buyer_emails = Enum.filter(emails, &(&1.to.id == buyer.id))
      supplier_emails = Enum.filter(emails, &(&1.to.id != buyer.id))

      for email <- buyer_emails do
        assert_delivered_email(email)
      end

      for email <- supplier_emails do
        assert_delivered_email(email)
      end

      AuctionsSupervisor.stop_child(auction)
    end
  end

  describe "non-event notifications" do
    test "uploading delivered coq produces email", %{auction: auction} do
      auction_supplier_coq =
        %AuctionSupplierCOQ{id: id} =
        insert(:auction_supplier_coq, auction: auction, delivered: true)

      assert %AuctionSupplierCOQ{id: ^id} =
               NonEventNotifier.emit(auction_supplier_coq, :coq_uploaded)

      emails = Emails.DeliveredCOQUploaded.generate(auction_supplier_coq)

      for email <- emails do
        assert_delivered_email(email)
      end

      AuctionsSupervisor.stop_child(auction)
    end

    test "non-delivered coq does not produce an email", %{auction: auction} do
      auction_supplier_coq =
        %AuctionSupplierCOQ{id: id} =
        insert(:auction_supplier_coq, auction: auction, delivered: false)

      assert %AuctionSupplierCOQ{id: ^id} =
               NonEventNotifier.emit(auction_supplier_coq, :coq_uploaded)

      emails = Emails.DeliveredCOQUploaded.generate(auction_supplier_coq)

      for email <- emails do
        refute_delivered_email(email)
      end

      AuctionsSupervisor.stop_child(auction)
    end
  end
end
