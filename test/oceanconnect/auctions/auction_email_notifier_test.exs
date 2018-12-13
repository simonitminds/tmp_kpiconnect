# TODO: maybe fix these flaky CI tests?
defmodule Oceanconnect.Auctions.AuctionEmailNotifierTest do
  use Oceanconnect.DataCase
  use Bamboo.Test

  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{AuctionEmailNotifier}

  setup do
    ocm = insert(:company, name: "Ocean Connect Marine", is_ocm: true, is_broker: true)
    buyer_company = insert(:company, is_supplier: false, broker_entity: ocm)
    buyers = insert_list(2, :user, company: buyer_company)

    [barge1, barge2] = insert_list(2, :barge)

    supplier_companies = [
      insert(:company, is_supplier: true),
      insert(:company, is_supplier: true)
    ]

    suppliers = Enum.map(supplier_companies, &insert(:user, %{company: &1}))
    auction_users = buyers ++ suppliers

    vessel = insert(:vessel)
    fuel = insert(:fuel)

    non_participating_suppliers =
      for company <- supplier_companies, do: insert(:user, company: company)

    non_participating_buyers = insert_list(2, :user, company: buyer_company)

    auction =
      insert(:auction,
        buyer: buyer_company,
        suppliers: supplier_companies,
        auction_vessel_fuels: [build(:vessel_fuel, vessel: vessel, fuel: fuel, quantity: 200)],
        scheduled_start: DateTime.utc_now(),
        is_traded_bid_allowed: true
      )
      |> Auctions.fully_loaded()

    approved_barges = [
      insert(:auction_barge, auction: auction, barge: barge1, supplier: hd(supplier_companies)),
      insert(:auction_barge,
        auction: auction,
        barge: barge2,
        supplier: List.last(supplier_companies)
      )
    ]

    winning_supplier_company = Enum.at(Enum.take_random(auction.suppliers, 1), 0)

    solution_bids = [
      create_bid(
        200.00,
        nil,
        hd(supplier_companies).id,
        "#{hd(auction.auction_vessel_fuels).id}",
        auction,
        true
      ),
      create_bid(
        200.00,
        nil,
        List.last(supplier_companies).id,
        "#{hd(auction.auction_vessel_fuels).id}",
        auction,
        false
      )
    ]

    %Auctions.AuctionStore.AuctionState{product_bids: product_bids} =
      Auctions.AuctionStore.AuctionState.from_auction(auction)

    winning_solution = Auctions.Solution.from_bids(solution_bids, product_bids, auction)

    {:ok,
     %{
       auction: auction,
       auction_users: auction_users,
       winning_supplier_company: winning_supplier_company,
       winning_solution: winning_solution,
       approved_barges: approved_barges
     }}
  end

  describe "auction notifier delivers emails" do
    #     test "auction notifier sends invitation emails to all invited suppliers", %{auction: auction} do
    #       assert {:ok, emails} = AuctionEmailNotifier.notify_auction_created(auction)
    #       :timer.sleep(500)
    #       assert length(emails) > 0

    #       for email <- emails do
    #         assert_delivered_email(email)
    #       end
    #     end

    #     test "auction notifier sends upcoming emails to participants", %{auction: auction} do
    #       assert {:ok, emails} = AuctionEmailNotifier.notify_upcoming_auction(auction)
    #       :timer.sleep(500)
    #       assert length(emails) > 0

    #       for email <- emails do
    #         assert_delivered_email(email)
    #       end
    #     end

    #     test "auction notifier sends cancellation emails to participants", %{auction: auction} do
    #       assert {:ok, emails} = AuctionEmailNotifier.notify_auction_canceled(auction)
    #       :timer.sleep(500)
    #       assert length(emails) > 0

    #       for email <- emails do
    #         assert_delivered_email(email)
    #       end
    #     end

    test "auction notifier sends completion emails to winning supplier and buyer", %{
      winning_solution: winning_solution,
      approved_barges: approved_barges,
      auction: auction,
      auction_users: auction_users
    } do
      active_participants = Enum.drop(auction_users, 2)

      assert {:ok, emails} =
               AuctionEmailNotifier.notify_auction_completed(
                 winning_solution.bids,
                 approved_barges,
                 auction.id,
                 active_participants
               )

      :timer.sleep(500)
      assert length(emails) == length(active_participants)
      assert length(emails) > 0

      for email <- emails do
        assert_delivered_email(email)
      end
    end
  end
end
