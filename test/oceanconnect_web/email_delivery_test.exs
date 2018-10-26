defmodule OceanconnectWeb.EmailDeliveryTest do
  use Oceanconnect.DataCase
  use Bamboo.Test

  alias OceanconnectWeb.Email
  alias OceanconnectWeb.Mailer
  alias Oceanconnect.Auctions

  setup do
    buyer_company = insert(:company, is_supplier: false)
    _ocm = insert(:company, name: "Ocean Connect Marine")
    barge1 = insert(:barge)
    barge2 = insert(:barge)

    supplier_companies = [
      insert(:company, is_supplier: true),
      insert(:company, is_supplier: true)
    ]

    auction =
      insert(:auction, buyer: buyer_company, suppliers: supplier_companies)
      |> Auctions.fully_loaded()

    approved_barges = [insert(:auction_barge, auction: auction, barge: barge1, supplier: hd(supplier_companies)), insert(:auction_barge, auction: auction, barge: barge2, supplier: List.last(supplier_companies))]
    winning_supplier_company = Enum.at(Enum.take_random(auction.suppliers, 1), 0)

    solution_bids = [create_bid(200, nil, hd(supplier_companies).id, hd(auction.auction_vessel_fuels).fuel.id, auction, true), create_bid(200, nil, List.last(supplier_companies).id, hd(auction.auction_vessel_fuels).fuel.id, auction, false)]

    %Auctions.AuctionStore.AuctionState{product_bids: product_bids} = Auctions.AuctionStore.AuctionState.from_auction(auction)

    winning_solution = Auctions.Solution.from_bids(solution_bids, product_bids, auction)

    {:ok, %{auction: auction, winning_supplier_company: winning_supplier_company, winning_solution: winning_solution, approved_barges: approved_barges}}
  end

  describe "sending emails" do
    test "sends auction invitation emails to all invited suppliers", %{auction: auction} do
      emails = Email.auction_invitation(auction)

      for email <- emails do
        Mailer.deliver_now(email)
        assert_delivered_email(email)
      end
    end

    test "sends auction starting soon emails to all participants", %{auction: auction} do
      %{supplier_emails: supplier_emails, buyer_emails: buyer_emails} =
        Email.auction_starting_soon(auction)

      for email <- List.flatten([supplier_emails | buyer_emails]) do
        Mailer.deliver_now(email)
      end
    end

    test "sends auction completion emails to winning supplier and buyer", %{
      auction: auction,
      approved_barges: approved_barges,
      winning_solution: winning_solution
    } do

      %{supplier_emails: supplier_emails, buyer_emails: buyer_emails} =
        Email.auction_closed(winning_solution.bids, approved_barges, auction)

      for supplier_email <- supplier_emails do
        Mailer.deliver_now(supplier_email)
        assert_delivered_email(supplier_email)
      end

      for buyer_email <- buyer_emails do
        Mailer.deliver_now(buyer_email)
        assert_delivered_email(buyer_email)
      end
    end

    test "sends action cancellation emails to all participants", %{auction: auction} do
      %{supplier_emails: supplier_emails, buyer_emails: buyer_emails} =
        Email.auction_canceled(auction)

      for supplier_email <- supplier_emails do
        Mailer.deliver_now(supplier_email)
        assert_delivered_email(supplier_email)
      end

      for buyer_email <- buyer_emails do
        Mailer.deliver_now(buyer_email)
        assert_delivered_email(buyer_email)
      end
    end
  end
end
