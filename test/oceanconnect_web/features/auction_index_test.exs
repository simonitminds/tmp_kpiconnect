defmodule Oceanconnect.AuctionIndexTest do
  use Oceanconnect.FeatureCase
  alias Oceanconnect.AuctionIndexPage


  setup do
    buyer_company = insert(:company)
    buyer = insert(:user, company: buyer_company)
    login_user(buyer)
    supplier_company = insert(:company, is_supplier: true)
    supplier = insert(:user, company: supplier_company)
    auctions = insert_list(2, :auction, buyer: buyer_company, suppliers: [supplier_company])
    {:ok, %{auctions: auctions, supplier: supplier}}
  end

  test "renders the default auction index page", %{auctions: auctions} do
    AuctionIndexPage.visit()
    assert AuctionIndexPage.is_current_path?()
    assert AuctionIndexPage.has_auctions?(auctions)
  end

  test "auction realtime start", %{auctions: auctions, supplier: supplier} do
    auction = hd(auctions)
    Oceanconnect.Auctions.AuctionsSupervisor.start_child(auction)
    AuctionIndexPage.visit()

    in_browser_session("supplier_session", fn ->
      login_user(supplier)
      AuctionIndexPage.visit()
      assert AuctionIndexPage.is_current_path?
      assert AuctionIndexPage.auction_is_status(auction, "pending")
    end)

    AuctionIndexPage.start_auction(auction)

    in_browser_session "supplier_session", fn ->
      assert AuctionIndexPage.is_current_path?()
      assert AuctionIndexPage.auction_is_status(auction, "open")
      :timer.sleep(500)
      assert AuctionIndexPage.time_remaining() |> convert_to_millisecs < auction.duration
    end
  end

  # test "buyer can see his view of the auction card", %{auctions: auctions} do
  #   auction = auctions |> hd
  #   buyer_params = %{
  #     suppliers: auction.suppliers
  #   }

    # AuctionIndexPage.visit()
    # assert AuctionIndexPage.has_values_from_params?(buyer_params)
  # end

  test "supplier can see his view of the auction card", %{supplier: supplier} do
    login_user(supplier)
    AuctionIndexPage.visit()
    assert has_css?(".qa-auction-invitation-controls")
    refute has_css?(".qa-auction-suppliers")
  end
end
