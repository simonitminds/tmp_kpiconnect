defmodule Oceanconnect.TermAuctionIndexTest do
  use Oceanconnect.FeatureCase

  alias Oceanconnect.Auctions
  alias Oceanconnect.AuctionIndexPage

  setup do
    buyer_company = insert(:company)
    buyer = insert(:user, company: buyer_company)
    supplier_company = insert(:company, is_supplier: true)
    supplier = insert(:user, company: supplier_company)
    auctions = insert_list(2, :term_auction, buyer: buyer_company, suppliers: [supplier_company])
    {:ok, %{auctions: auctions, buyer: buyer, supplier: supplier}}
  end

  describe "buyer login" do
    setup %{auctions: auctions, buyer: buyer} do
      auction = auctions |> hd |> Auctions.fully_loaded()

      {:ok, _pid} =
        start_supervised(
          {Oceanconnect.Auctions.AuctionSupervisor, {auction, %{handle_events: true}}}
        )

      login_user(buyer)
      AuctionIndexPage.visit()
      {:ok, auction: auction}
    end

    test "renders the default auction index page", %{auctions: auctions} do
      assert AuctionIndexPage.is_current_path?()
      assert AuctionIndexPage.has_auctions?(auctions)
    end

    test "term auction buyer card shows correct information", %{auction: auction} do
      assert AuctionIndexPage.has_field_in_auction?(auction.id, "buyer-card")
      assert AuctionIndexPage.has_field_in_auction?(auction.id, "forward_fixed")
      assert AuctionIndexPage.has_field_in_auction?(auction.id, "port")
    end

    test "user can only see auctions they participate in", %{auctions: auctions} do
      non_participant_auctions = insert_list(2, :auction)
      supplier_auction = insert(:auction, suppliers: [hd(auctions).buyer])

      AuctionIndexPage.visit()
      assert AuctionIndexPage.has_auctions?(auctions ++ [supplier_auction])
      refute AuctionIndexPage.has_auctions?(non_participant_auctions)
    end
  end

  describe "supplier login" do
    setup %{auctions: auctions, supplier: supplier} do
      auction =
        auctions
        |> hd()
        |> Auctions.fully_loaded()

      {:ok, _pid} =
        start_supervised(
          {Oceanconnect.Auctions.AuctionSupervisor,
           {auction, %{exclude_children: [:auction_reminder_timer, :auction_scheduler]}}}
        )

      login_user(supplier)
      AuctionIndexPage.visit()
      {:ok, %{auction: auction}}
    end

    test "supplier can see his view of the auction card", %{auction: auction} do
      # Temporarily removed parameter "invitation-controls"
      assert AuctionIndexPage.has_field_in_auction?(auction.id, "supplier-card")
      assert AuctionIndexPage.has_field_in_auction?(auction.id, "forward_fixed")
      assert AuctionIndexPage.has_field_in_auction?(auction.id, "port")
      # Temporarily removed parameter "suppliers"
      refute AuctionIndexPage.has_field_in_auction?(auction.id, "buyer-card")
    end

    test "supplier sees realtime start", %{auction: auction} do
      assert AuctionIndexPage.is_current_path?()
      assert AuctionIndexPage.auction_is_status?(auction, "pending")

      Oceanconnect.Auctions.start_auction(auction)

      assert AuctionIndexPage.is_current_path?()
      assert AuctionIndexPage.auction_is_status?(auction, "open")
      :timer.sleep(400)
      assert AuctionIndexPage.time_remaining() |> convert_to_millisecs < auction.duration
    end
  end
end
