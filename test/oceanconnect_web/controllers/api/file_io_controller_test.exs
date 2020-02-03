defmodule OceanconnectWeb.Api.FileIOControllerTest do
  use OceanconnectWeb.ConnCase
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{Auction, AuctionPayload, AuctionSupplierCOQ, TermAuction}

  setup do
    buyer_company = insert(:company, is_supplier: true)
    buyer = insert(:user, company: buyer_company)
    supplier_company = insert(:company, is_supplier: true)
    supplier = insert(:user, company: supplier_company)
    supplier2_company = insert(:company, is_supplier: true)
    supplier2 = insert(:user, company: supplier2_company)
    vessel_fuels = insert_list(2, :vessel_fuel)
    fuel = vessel_fuels |> hd() |> Map.get(:fuel)

    auction =
      insert(:auction,
        buyer: buyer_company,
        auction_vessel_fuels: vessel_fuels,
        suppliers: [supplier_company, supplier2_company]
      )
      |> Auctions.fully_loaded()

    existing_coq =
      insert(:auction_supplier_coq, auction: auction, fuel: fuel, supplier: supplier_company)

    term_auction =
      insert(:term_auction,
        buyer: buyer_company,
        fuel: fuel,
        suppliers: [supplier_company, supplier2_company]
      )
      |> Auctions.fully_loaded()

    {:ok, _pid} =
      start_supervised(
        {Oceanconnect.Auctions.AuctionSupervisor,
         {auction,
          %{
            exclude_children: [
              :auction_reminder_timer,
              :auction_event_handler,
              :auction_scheduler
            ]
          }}}
      )

    {:ok,
     %{
       auction: auction,
       term_auction: term_auction,
       fuel: fuel,
       buyer: buyer,
       existing_coq: existing_coq,
       supplier: supplier,
       supplier2: supplier2,
       supplier_company: supplier_company,
       supplier2_company: supplier2_company
     }}
  end

  describe "user must be authenticated" do
    test "to upload coq", %{
      auction: %{id: auction_id},
      fuel: %{id: fuel_id},
      supplier_company: %{id: supplier_company_id}
    } do
      conn = build_conn()

      conn =
        post(
          conn,
          file_io_api_path(conn, :upload_coq, auction_id, supplier_company_id, fuel_id)
        )

      assert conn.resp_body == "\"Unauthorized\""
    end

    test "to delete coq", %{
      existing_coq: %{id: existing_coq_id}
    } do
      conn = build_conn()
      conn = delete(conn, file_io_api_path(conn, :delete_coq, existing_coq_id))

      assert conn.resp_body == "\"Unauthorized\""
    end
  end

  describe "an admin" do
    setup do
      admin = insert(:user, is_admin: true)

      authed_conn =
        build_conn()
        |> OceanconnectWeb.Plugs.Auth.api_login(admin)
        |> Plug.Conn.put_req_header("content-type", "application/pdf")

      {:ok, %{conn: authed_conn}}
    end

    test "can upload coq", %{
      conn: conn,
      auction: %{id: auction_id},
      fuel: %{id: fuel_id},
      supplier2_company: %{id: supplier2_company_id}
    } do
      conn =
        post(
          conn,
          file_io_api_path(conn, :upload_coq, auction_id, supplier2_company_id, fuel_id)
        )

      assert 200 == conn.status

      assert %AuctionPayload{auction: %Auction{auction_supplier_coqs: supplier_coqs}} =
               conn.assigns.auction_payload

      assert %AuctionSupplierCOQ{
               id: new_coq_id,
               auction_id: ^auction_id,
               fuel_id: ^fuel_id,
               supplier_id: ^supplier2_company_id,
               file_extension: "pdf"
             } = hd(supplier_coqs)

      assert %AuctionSupplierCOQ{} = Auctions.get_auction_supplier_coq(new_coq_id)
    end

    test "can delete coq", %{
      conn: conn,
      existing_coq: %{id: existing_coq_id}
    } do
      conn = delete(conn, file_io_api_path(conn, :delete_coq, existing_coq_id))

      assert 200 == conn.status

      assert %AuctionPayload{auction: %Auction{auction_supplier_coqs: []}} =
               conn.assigns.auction_payload

      assert nil == Auctions.get_auction_supplier_coq(existing_coq_id)
    end
  end

  describe "a buyer" do
    setup %{buyer: buyer} do
      authed_conn =
        build_conn()
        |> OceanconnectWeb.Plugs.Auth.api_login(buyer)
        |> Plug.Conn.put_req_header("content-type", "application/pdf")

      {:ok, %{conn: authed_conn}}
    end

    test "can NOT upload coq", %{
      conn: conn,
      auction: %{id: auction_id},
      fuel: %{id: fuel_id},
      supplier2_company: %{id: supplier2_company_id}
    } do
      conn =
        post(
          conn,
          file_io_api_path(conn, :upload_coq, auction_id, supplier2_company_id, fuel_id)
        )

      assert 422 == conn.status
      assert [] == Auctions.get_auction!(auction_id).auction_supplier_coqs
    end

    test "can NOT delete coq", %{
      conn: conn,
      existing_coq: %{id: existing_coq_id}
    } do
      conn = delete(conn, file_io_api_path(conn, :delete_coq, existing_coq_id))

      assert 422 == conn.status
      assert %AuctionSupplierCOQ{} = Auctions.get_auction_supplier_coq(existing_coq_id)
    end
  end

  describe "a supplier" do
    setup %{supplier: supplier} do
      authed_conn =
        build_conn()
        |> OceanconnectWeb.Plugs.Auth.api_login(supplier)
        |> Plug.Conn.put_req_header("content-type", "application/pdf")

      {:ok, %{conn: authed_conn}}
    end

    test "can upload coq", %{
      auction: %{id: auction_id},
      fuel: %{id: fuel_id},
      supplier2_company: %{id: supplier2_company_id},
      supplier2: supplier2
    } do
      authed_conn =
        build_conn()
        |> OceanconnectWeb.Plugs.Auth.api_login(supplier2)
        |> Plug.Conn.put_req_header("content-type", "application/pdf")

      conn =
        post(
          authed_conn,
          file_io_api_path(authed_conn, :upload_coq, auction_id, supplier2_company_id, fuel_id)
        )

      assert 200 == conn.status

      assert %AuctionPayload{auction: %Auction{auction_supplier_coqs: supplier_coqs}} =
               conn.assigns.auction_payload

      assert %AuctionSupplierCOQ{
               id: new_coq_id,
               auction_id: ^auction_id,
               fuel_id: ^fuel_id,
               supplier_id: ^supplier2_company_id,
               file_extension: "pdf"
             } = hd(supplier_coqs)

      assert %AuctionSupplierCOQ{} = Auctions.get_auction_supplier_coq(new_coq_id)
    end

    test "can upload coq for term auction", %{
      term_auction: %{id: term_auction_id},
      fuel: %{id: fuel_id},
      supplier2_company: %{id: supplier2_company_id},
      supplier2: supplier2
    } do
      authed_conn =
        build_conn()
        |> OceanconnectWeb.Plugs.Auth.api_login(supplier2)
        |> Plug.Conn.put_req_header("content-type", "application/pdf")

      conn =
        post(
          authed_conn,
          file_io_api_path(
            authed_conn,
            :upload_coq,
            term_auction_id,
            supplier2_company_id,
            fuel_id
          )
        )

      assert 200 == conn.status

      assert %AuctionPayload{auction: %TermAuction{auction_supplier_coqs: supplier_coqs}} =
               conn.assigns.auction_payload

      assert %AuctionSupplierCOQ{
               id: new_coq_id,
               term_auction_id: ^term_auction_id,
               fuel_id: ^fuel_id,
               supplier_id: ^supplier2_company_id,
               file_extension: "pdf"
             } = hd(supplier_coqs)

      assert %AuctionSupplierCOQ{} = Auctions.get_auction_supplier_coq(new_coq_id)
    end

    test "can update existing coq", %{
      conn: conn,
      existing_coq: %{auction_id: auction_id, fuel_id: fuel_id, supplier_id: supplier_company_id}
    } do
      updated_conn =
        conn
        |> Plug.Conn.delete_resp_header("content-type")
        |> Plug.Conn.put_req_header("content-type", "image/png")

      conn =
        post(
          updated_conn,
          file_io_api_path(conn, :upload_coq, auction_id, supplier_company_id, fuel_id)
        )

      assert 200 == conn.status

      assert %AuctionPayload{auction: %Auction{auction_supplier_coqs: supplier_coqs}} =
               conn.assigns.auction_payload

      assert %AuctionSupplierCOQ{
               auction_id: ^auction_id,
               fuel_id: ^fuel_id,
               supplier_id: ^supplier_company_id,
               file_extension: "png"
             } = hd(supplier_coqs)
    end

    test "can delete coq", %{
      conn: conn,
      existing_coq: %{id: existing_coq_id}
    } do
      conn = delete(conn, file_io_api_path(conn, :delete_coq, existing_coq_id))

      assert 200 == conn.status

      assert %AuctionPayload{auction: %Auction{auction_supplier_coqs: []}} =
               conn.assigns.auction_payload

      assert nil == Auctions.get_auction_supplier_coq(existing_coq_id)
    end

    test "can NOT delete coq of other supplier", %{
      supplier2: supplier2,
      existing_coq: %{id: existing_coq_id}
    } do
      authed_conn =
        build_conn()
        |> OceanconnectWeb.Plugs.Auth.api_login(supplier2)
        |> Plug.Conn.put_req_header("content-type", "application/pdf")

      conn = delete(authed_conn, file_io_api_path(authed_conn, :delete_coq, existing_coq_id))

      assert 422 == conn.status
      assert %AuctionSupplierCOQ{} = Auctions.get_auction_supplier_coq(existing_coq_id)
    end
  end
end
