defmodule Oceanconnect.MessagesTest do
  use Oceanconnect.FeatureCase
  alias Oceanconnect.{Auctions, AuctionIndexPage, AuctionShowPage, MessagesPage}

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

    messages = insert_list(3, :message, auction: auction, author_company: buyer_company, recipient_company: supplier_company)

    {:ok, %{auction: auction, buyer: buyer, messages: messages, supplier: supplier}}
  end

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
      MessagesPage.open_message_window()
      assert MessagesPage.has_participating_auctions?([auction])
    end

    test "buyer can see chat window on show page with all auctions", %{auction: auction} do
      AuctionShowPage.visit(auction.id)
      assert AuctionShowPage.is_current_path?(auction.id)
      MessagesPage.open_message_window()
      assert MessagesPage.has_participating_auctions?([auction])
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
      MessagesPage.open_message_window()
      assert MessagesPage.has_participating_auctions?([auction])
    end

    test "supplier can see chat window on show page with all auctions", %{auction: auction} do
      AuctionShowPage.visit(auction.id)
      assert AuctionShowPage.is_current_path?(auction.id)
      MessagesPage.open_message_window()
      assert MessagesPage.has_participating_auctions?([auction])
    end

    test "unseen messages are marked as seen when recipient expands conversation", %{auction: auction, messages: messages, supplier_company: supplier_company} do
      AuctionShowPage.visit(auction.id)
      MessagesPage.open_auction_conversation(auction.id, auction.buyer.name)
      assert Enum.all?(messages, &MessagesPage.message_is_unseen?(&1))
    end
  end
end
