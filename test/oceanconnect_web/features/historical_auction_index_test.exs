defmodule OceanconnectWeb.HistoricalAuctionIndexTest do
  use Oceanconnect.FeatureCase
  alias Oceanconnect.{Auction.HistoricalIndexPage, AuctionIndexPage, AdminPage}
  alias Oceanconnect.Auctions

  setup do
    buyer_company = insert(:company)
    buyer = insert(:user, company: buyer_company)
    supplier_company = insert(:company, is_supplier: true)
    supplier_company2 = insert(:company, is_supplier: true)
    port = insert(:port)
    port2 = insert(:port)
    supplier = insert(:user, company: supplier_company)
    [vessel_fuel1, vessel_fuel2] = insert_list(2, :vessel_fuel)
    open_auction = insert(:auction, buyer: buyer_company, suppliers: [supplier_company])

    closed_auction1 =
      insert(:auction,
        port: port,
        auction_vessel_fuels: [vessel_fuel1],
        buyer: buyer_company,
        suppliers: [supplier_company],
        finalized: true,
        claims: [
          insert(:claim,
            closed: false,
            supplier: supplier_company,
            notice_recipient: supplier_company
          )
        ]
      )

    closed_auction2 =
      insert(:auction,
        port: port2,
        auction_vessel_fuels: [vessel_fuel2],
        buyer: buyer_company,
        suppliers: [supplier_company2],
        finalized: true,
        claims: [
          insert(:claim,
            closed: true,
            supplier: supplier_company,
            notice_recipient: supplier_company
          )
        ]
      )

    vessel1 = vessel_fuel1.vessel
    vessel2 = vessel_fuel2.vessel

    open_auction =
      open_auction
      |> Auctions.fully_loaded()

    closed_auction1 =
      closed_auction1
      |> Auctions.fully_loaded()

    closed_auction2 =
      closed_auction2
      |> Auctions.fully_loaded()

    start_auction!(open_auction)
    close_auction!(closed_auction1)
    close_auction!(closed_auction2)
    closed_auctions = [closed_auction1, closed_auction2]

    {:ok,
     %{
       open_auction: open_auction,
       closed_auctions: closed_auctions,
       buyer: buyer,
       supplier: supplier,
       supplier_company: supplier_company,
       port: port,
       closed_auction1: closed_auction1,
       closed_auction2: closed_auction2,
       vessel1: vessel1
     }}
  end

  describe "buyer" do
    setup %{buyer: buyer} do
      login_user(buyer)
      AuctionIndexPage.visit()
      {:ok, %{}}
    end

    test "can see current auction index page with open auctions", %{
      open_auction: open_auction,
      closed_auctions: closed_auctions
    } do
      assert AuctionIndexPage.is_current_path?()
      assert AuctionIndexPage.has_auctions?([open_auction])
      refute AuctionIndexPage.has_auctions?(closed_auctions)
    end

    test "can visit historical auction index page and see closed auctions", %{
      closed_auctions: closed_auctions,
      open_auction: open_auction
    } do
      HistoricalIndexPage.visit()
      assert HistoricalIndexPage.is_current_path?()
      assert HistoricalIndexPage.has_auctions?(closed_auctions)
      refute HistoricalIndexPage.has_auctions?([open_auction])
    end

    test "can filter historical auctions by vessel", %{
      closed_auction1: closed_auction1,
      closed_auction2: closed_auction2,
      vessel1: vessel1
    } do
      HistoricalIndexPage.visit()
      HistoricalIndexPage.filter_vessel(vessel1.id)
      assert HistoricalIndexPage.is_current_path?()
      assert HistoricalIndexPage.has_auctions?([closed_auction1])
      refute HistoricalIndexPage.has_auctions?([closed_auction2])
    end

    test "can filter historical auctions by supplier", %{
      closed_auction1: closed_auction1,
      closed_auction2: closed_auction2,
      supplier_company: supplier_company
    } do
      HistoricalIndexPage.visit()
      HistoricalIndexPage.filter_supplier(supplier_company.id)
      assert HistoricalIndexPage.is_current_path?()
      assert HistoricalIndexPage.has_auctions?([closed_auction1])
      refute HistoricalIndexPage.has_auctions?([closed_auction2])
    end

    test "can filter historical auctions by port", %{
      closed_auction1: closed_auction1,
      closed_auction2: closed_auction2,
      port: port
    } do
      HistoricalIndexPage.visit()
      HistoricalIndexPage.filter_port(port.id)
      assert HistoricalIndexPage.is_current_path?()
      assert HistoricalIndexPage.has_auctions?([closed_auction1])
      refute HistoricalIndexPage.has_auctions?([closed_auction2])
    end

    test "can filter histoircal auctions by claim status", %{
      closed_auctions: closed_auctions,
      closed_auction1: closed_auction1,
      closed_auction2: closed_auction2
    } do
      HistoricalIndexPage.visit()
      assert HistoricalIndexPage.is_current_path?()
      assert HistoricalIndexPage.has_auctions?(closed_auctions)

      HistoricalIndexPage.filter_claim_status(:open)
      assert HistoricalIndexPage.has_auctions?([closed_auction1])
      refute HistoricalIndexPage.has_auctions?([closed_auction2])

      HistoricalIndexPage.filter_claim_status(:closed)
      assert HistoricalIndexPage.has_auctions?([closed_auction2])
      refute HistoricalIndexPage.has_auctions?([closed_auction1])
    end
  end
end
