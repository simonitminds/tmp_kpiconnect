defmodule Oceanconnect.AuctionIndexTest do
  use Oceanconnect.FeatureCase
  alias Oceanconnect.AuctionIndexPage
  alias Oceanconnect.AdminPage
  alias Oceanconnect.Auctions

  setup do
    buyer_company = insert(:company)
    buyer = insert(:user, company: buyer_company)
    supplier_company = insert(:company, is_supplier: true)
    supplier = insert(:user, company: supplier_company)
    auctions = insert_list(2, :auction, buyer: buyer_company, suppliers: [supplier_company])
    {:ok, %{auctions: auctions, buyer: buyer, supplier: supplier}}
  end

  test "canceling an auction", %{auctions: [auction | _rest], buyer: buyer} do
    auction = auction |> Oceanconnect.Auctions.fully_loaded()
    Oceanconnect.Auctions.AuctionsSupervisor.start_child(auction)
    login_user(buyer)
    AuctionIndexPage.visit()
    :timer.sleep(500)
    AuctionIndexPage.cancel_auction(auction)
    :timer.sleep(500)
    assert AuctionIndexPage.auction_is_status?(auction, "canceled")
  end

  describe "buyer login" do
    setup %{auctions: auctions, buyer: buyer} do
      auction = auctions |> hd |> Oceanconnect.Auctions.fully_loaded()

      {:ok, _pid} =
        start_supervised(
          {Oceanconnect.Auctions.AuctionSupervisor, {auction, %{handle_events: true}}}
        )

      login_user(buyer)
      AuctionIndexPage.visit()
      {:ok, %{auction: auction}}
    end

    test "renders the default auction index page", %{auctions: auctions} do
      assert AuctionIndexPage.is_current_path?()
      assert AuctionIndexPage.has_auctions?(auctions)
    end

    test "buyer can see his view of the auction card", %{auction: auction} do
      # Temporarily removed parameter "suppliers"
      assert AuctionIndexPage.has_field_in_auction?(auction.id, "buyer-card")
    end

    test "buyer/supplier can see his respective view per auction", %{auction: auction} do
      supplier_auction = insert(:auction, suppliers: [auction.buyer])

      AuctionIndexPage.visit()
      # Temporarily removed parameter "suppliers"
      assert AuctionIndexPage.has_field_in_auction?(auction.id, "buyer-card")
      # Temporarily removed parameter "invitation-controls"
      assert AuctionIndexPage.has_field_in_auction?(supplier_auction.id, "supplier-card")
    end

    test "user can only see auctions they participate in", %{auctions: auctions} do
      non_participant_auctions = insert_list(2, :auction)
      supplier_auction = insert(:auction, suppliers: [hd(auctions).buyer])

      AuctionIndexPage.visit()
      assert AuctionIndexPage.has_auctions?(auctions ++ [supplier_auction])
      refute AuctionIndexPage.has_auctions?(non_participant_auctions)
    end
  end

  describe "admin login" do
    setup %{auctions: auctions, buyer: buyer} do
      admin_company = insert(:company)
      admin = insert(:user, company: admin_company, is_admin: true)
      auction = auctions |> hd |> Oceanconnect.Auctions.fully_loaded()

      {:ok, _pid} =
        start_supervised(
          {Oceanconnect.Auctions.AuctionSupervisor, {auction, %{handle_events: true}}}
        )

      login_user(admin)
      AuctionIndexPage.visit()
      {:ok, %{auction: auction, buyer: buyer}}
    end

    test "can start auction manually with start auction button when impersonating a buyer", %{
      auction: auction,
      buyer: buyer
    } do
      AdminPage.impersonate_user(buyer)
      assert AdminPage.logged_in_as?(buyer)
      # Ensures auction card is rendered after reveal animation
      :timer.sleep(1_000)
      assert AuctionIndexPage.auction_is_status?(auction, "pending")
      AuctionIndexPage.start_auction(auction)
      # Ensures auction card is rendered after reveal animation
      :timer.sleep(1_000)
      assert AuctionIndexPage.auction_is_status?(auction, "open")
    end
  end

  describe "supplier login" do
    setup %{auctions: auctions, supplier: supplier} do
      auction = auctions
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
