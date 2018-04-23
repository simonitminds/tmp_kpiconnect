defmodule Oceanconnect.AuctionIndexTest do
  use Oceanconnect.FeatureCase
  alias Oceanconnect.AuctionIndexPage


  setup do
    buyer_company = insert(:company)
    buyer = insert(:user, company: buyer_company)
    supplier_company = insert(:company, is_supplier: true)
    supplier = insert(:user, company: supplier_company)
    auctions = insert_list(2, :auction, buyer: buyer_company, suppliers: [supplier_company])
    {:ok, %{auctions: auctions, buyer: buyer, supplier: supplier}}
  end

  describe "buyer login" do
    setup %{auctions: auctions, buyer: buyer} do
      auction = auctions |> hd
      {:ok, _pid} = start_supervised({Oceanconnect.Auctions.AuctionSupervisor, auction})
      login_user(buyer)
      AuctionIndexPage.visit()
      {:ok, %{auction: auction}}
    end

    test "renders the default auction index page", %{auctions: auctions} do
      assert AuctionIndexPage.is_current_path?()
      assert AuctionIndexPage.has_auctions?(auctions)
    end

    test "buyer can see his view of the auction card", %{auction: auction} do
      assert AuctionIndexPage.has_field_in_auction?(auction.id, "suppliers")
    end

    test "buyer/supplier can see his respective view per auction", %{auction: auction} do
      supplier_auction = insert(:auction, suppliers: [auction.buyer])

      AuctionIndexPage.visit()
      assert AuctionIndexPage.has_field_in_auction?(auction.id, "suppliers")
      assert AuctionIndexPage.has_field_in_auction?(supplier_auction.id, "invitation-controls")
    end

    test "user can only see auctions they participate in", %{auctions: auctions} do
      non_participant_auctions = insert_list(2, :auction)
      supplier_auction = insert(:auction, suppliers: [hd(auctions).buyer])

      AuctionIndexPage.visit()
      assert AuctionIndexPage.has_auctions?(auctions ++ [supplier_auction])
      refute AuctionIndexPage.has_auctions?(non_participant_auctions)
    end

    test "can start auction manually with start auction button", %{auction: auction} do
      :timer.sleep(1_000) # Ensures auction card is rendered after reveal animation
      assert AuctionIndexPage.auction_is_status?(auction, "pending")
      AuctionIndexPage.start_auction(auction)
      :timer.sleep(1_000) # Ensures auction card is rendered after reveal animation
      assert AuctionIndexPage.auction_is_status?(auction, "open")
    end
  end


  describe "supplier login" do
    setup %{auctions: auctions, supplier: supplier} do
      auction = auctions |> hd
      {:ok, _pid} = start_supervised({Oceanconnect.Auctions.AuctionSupervisor, auction})
      login_user(supplier)
      AuctionIndexPage.visit()
      {:ok, %{auction: auction}}
    end

    test "supplier can see his view of the auction card", %{auction: auction} do
      assert AuctionIndexPage.has_field_in_auction?(auction.id, "invitation-controls")
      refute AuctionIndexPage.has_field_in_auction?(auction.id, "suppliers")
    end

    test "supplier sees realtime start", %{auction: auction} do
      assert AuctionIndexPage.is_current_path?
      assert AuctionIndexPage.auction_is_status?(auction, "pending")

      Oceanconnect.Auctions.start_auction(auction)

      assert AuctionIndexPage.is_current_path?()
      assert AuctionIndexPage.auction_is_status?(auction, "open")
      :timer.sleep(500)
      assert AuctionIndexPage.time_remaining() |> convert_to_millisecs < auction.duration
    end
  end
end
