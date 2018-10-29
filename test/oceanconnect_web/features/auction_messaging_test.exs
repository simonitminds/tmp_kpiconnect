defmodule Oceanconnect.AuctionMessagingTest do
  use Oceanconnect.FeatureCase
  alias Oceanconnect.{AuctionIndexPage, AuctionMessagingPage, AuctionShowPage}
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

    test "admin can see a list of all auctions in the chat window", %{auctions: auctions} do
      assert AuctionIndexPage.is_current_path?()
      AuctionMessagingPage.open_messaging_window()
      assert AuctionMessagingPage.has_participating_auctions?(auctions)
    end

    # TODO: test will not pass until Admin can see all ongoing auctions
    # test "admin can see chat window on show page with all auctions", %{auctions: auctions} do
    #   [auction | _tail] = auctions
    #   AuctionShowPage.visit(auction.id)
    #   assert AuctionShowPage.is_current_path?(auction.id)
    #   AuctionMessagingPage.open_messaging_window()
    #   assert AuctionMessagingPage.has_participating_auctions?(auctions)
    # end
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

    test "buyer can see a list of all participating auctions in the chat window", %{auctions: auctions} do
      assert AuctionIndexPage.is_current_path?()
      Hound.Helpers.Screenshot.take_screenshot()
      AuctionMessagingPage.open_messaging_window()
      assert AuctionMessagingPage.has_participating_auctions?(auctions)
    end

    test "buyer can see chat window on show page with all auctions", %{auctions: auctions} do
      [auction | _tail] = auctions
      AuctionShowPage.visit(auction.id)
      assert AuctionShowPage.is_current_path?(auction.id)
      AuctionMessagingPage.open_messaging_window()
      assert AuctionMessagingPage.has_participating_auctions?(auctions)
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
      {:ok, %{auction: auction, auctions: auctions}}
    end

    test "supplier can see a list of all participating auctions in the chat window", %{auctions: auctions} do
      assert AuctionIndexPage.is_current_path?()
      AuctionMessagingPage.open_messaging_window()
      assert AuctionMessagingPage.has_participating_auctions?(auctions)
    end

    test "supplier can see chat window on show page with all auctions", %{auctions: auctions} do
      [auction | _tail] = auctions
      AuctionShowPage.visit(auction.id)
      assert AuctionShowPage.is_current_path?(auction.id)
      AuctionMessagingPage.open_messaging_window()
      assert AuctionMessagingPage.has_participating_auctions?(auctions)
    end
  end
end
