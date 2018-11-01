defmodule Oceanconnect.MessagesTest do
  use Oceanconnect.FeatureCase
  alias Oceanconnect.{AuctionIndexPage, AuctionMessagePage, AuctionShowPage}
  alias Oceanconnect.AdminPage
  alias Oceanconnect.Auctions

  setup do
    buyer_company = insert(:company)
    buyer = insert(:user, company: buyer_company)
    supplier_company = insert(:company, is_supplier: true)
    supplier = insert(:user, company: supplier_company)
    vessel = insert(:vessel)
    fuel = insert(:fuel)

    auction =
      :auction
      |> insert(buyer: buyer_company, suppliers: [supplier_company], vessels: [vessel], auction_vessel_fuels: [build(:vessel_fuel, vessel: vessel, fuel: fuel)])
      |> Auctions.fully_loaded()

    {:ok, %{auction: auction, buyer: buyer, supplier: supplier}}
  end

  # TODO: test will not pass until Admin can see all ongoing auctions
  # describe "admin login" do
  #   setup %{auction: auction, buyer: buyer} do
  #     admin_company = insert(:company)
  #     admin = insert(:user, company: admin_company, is_admin: true)
  #
  #     {:ok, _pid} =
  #       start_supervised(
  #         {Oceanconnect.Auctions.AuctionSupervisor, {auction, %{handle_events: true}}}
  #       )
  #
  #     login_user(admin)
  #     AuctionIndexPage.visit()
  #     {:ok, %{auction: auction, buyer: buyer}}
  #   end
  #
  #   test "admin can see a list of all auctions in the chat window", %{auction: auction} do
  #     assert AuctionIndexPage.is_current_path?()
  #     AuctionMessagePage.open_message_window()
  #     assert AuctionMessagePage.has_participating_auctions?([auction])
  #   end
  #
  #   test "admin can see chat window on show page with all auctions", %{auctions: auctions} do
  #     [auction | _tail] = auctions
  #     AuctionShowPage.visit(auction.id)
  #     assert AuctionShowPage.is_current_path?(auction.id)
  #     AuctionMessagePage.open_message_window()
  #     assert AuctionMessagePage.has_participating_auctions?(auctions)
  #   end
  # end

  describe "buyer login" do
    setup %{auction: auction, buyer: buyer} do

      {:ok, _pid} =
        start_supervised(
          {Oceanconnect.Auctions.AuctionSupervisor, {auction, %{handle_events: true}}}
        )

      login_user(buyer)
      AuctionIndexPage.visit()
      {:ok, %{auction: auction}}
    end

    test "buyer can see a list of all participating auctions in the chat window", %{auction: auction} do
      assert AuctionIndexPage.is_current_path?()
      AuctionMessagePage.open_message_window()
      assert AuctionMessagePage.has_participating_auctions?([auction])
    end

    test "buyer can see chat window on show page with all auctions", %{auction: auction} do
      AuctionShowPage.visit(auction.id)
      assert AuctionShowPage.is_current_path?(auction.id)
      AuctionMessagePage.open_message_window()
      assert AuctionMessagePage.has_participating_auctions?([auction])
    end
  end

  describe "supplier login" do
    setup %{auction: auction, supplier: supplier} do

      {:ok, _pid} =
        start_supervised(
          {Oceanconnect.Auctions.AuctionSupervisor,
           {auction, %{exclude_children: [:auction_reminder_timer, :auction_scheduler]}}}
        )

      login_user(supplier)
      AuctionIndexPage.visit()
      {:ok, %{auction: auction}}
    end

    test "supplier can see a list of all participating auctions in the chat window", %{auction: auction} do
      assert AuctionIndexPage.is_current_path?()
      AuctionMessagePage.open_message_window()
      assert AuctionMessagePage.has_participating_auctions?([auction])
    end

    test "supplier can see chat window on show page with all auctions", %{auction: auction} do
      AuctionShowPage.visit(auction.id)
      assert AuctionShowPage.is_current_path?(auction.id)
      AuctionMessagePage.open_message_window()
      assert AuctionMessagePage.has_participating_auctions?([auction])
    end
  end
end
