defmodule OceanconnectWeb.AuctionControllerTest do
  use OceanconnectWeb.ConnCase

  alias Oceanconnect.Auctions

  @update_attrs %{ "duration" => 15}
  @invalid_attrs %{ "vessel_id" => nil}

  setup do
    buyer_company = insert(:company, is_supplier: true)
    buyer = insert(:user, company: buyer_company)
    vessel = insert(:vessel, company: buyer_company)
    fuel = insert(:fuel)
    supplier_company = insert(:company, is_supplier: true)
    supplier = insert(:user, company: supplier_company)
    port = insert(:port, companies: [buyer_company, supplier_company])
    auction_params = string_params_for(:auction, vessel: vessel, fuel: fuel, port: port)
    |> Oceanconnect.Utilities.maybe_convert_date_times
    |> Map.put("suppliers", %{"supplier-#{supplier_company.id}" => "#{supplier_company.id}"})
    authed_conn = login_user(build_conn(), buyer)
    auction = insert(:auction, port: port, buyer: buyer_company, vessel: vessel, suppliers: [supplier_company])
    {:ok, conn: authed_conn, valid_auction_params: auction_params,
          auction: auction, buyer: buyer_company,
          supplier: supplier, supplier_company: supplier_company}
  end

  describe "index" do
    test "lists all auctions", %{conn: conn} do
      conn = get conn, auction_path(conn, :index)
      assert html_response(conn, 200)
    end
  end

  describe "new auction" do
    test "renders form", %{conn: conn} do
      conn = get conn, auction_path(conn, :new)
      assert html_response(conn, 200) =~ "New Auction"
    end

    test "vessels are filtered by logged in buyers company", %{conn: conn, buyer: buyer} do
      conn = get(conn, auction_path(conn, :new))
      assert conn.assigns[:vessels] == buyer
      |> Auctions.vessels_for_buyer
      |> Auctions.strip_non_loaded
      |> Poison.encode!
    end
  end

  describe "auction create/edit data check" do
    test "ensures serialized data doesn't include password", %{conn: conn, auction: auction} do
      new = get conn, auction_path(conn, :new)
      create_fail = post(conn, auction_path(conn, :create), auction: @invalid_attrs)
      edit = get conn, auction_path(conn, :edit, auction)
      update_fail = put(conn, auction_path(conn, :update, auction), auction: @invalid_attrs)

      Enum.map([new, create_fail, edit, update_fail], fn(conn) ->
        json_auction = conn.assigns[:json_auction]
        refute json_auction =~ "password"
        refute json_auction =~ "password_hash"
      end)
    end
  end

  describe "create auction" do
    setup(%{buyer: buyer}) do
      port = insert(:port)
      invalid_attrs = Map.merge(@invalid_attrs, %{port_id: port.id, buyer_id: buyer.id})
      {:ok, %{invalid_attrs: invalid_attrs}}
    end

    test "redirects to show when data is valid", %{conn: conn, valid_auction_params: valid_auction_params, buyer: buyer, supplier_company: supplier_company} do
      updated_params = valid_auction_params
      |> Map.put("duration", round(valid_auction_params["duration"] / 60_000))
      |> Map.put("decision_duration", round(valid_auction_params["decision_duration"] / 60_000))
      conn = post(conn, auction_path(conn, :create), auction: updated_params)
      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == auction_path(conn, :show, id)

      auction = Oceanconnect.Repo.get(Auctions.Auction, id) |> Oceanconnect.Repo.preload([:vessel, :suppliers])
      conn = get conn, auction_path(conn, :show, id)
      assert html_response(conn, 200) =~ "window.userToken"
      assert auction.buyer_id == buyer.id
      assert List.first(auction.suppliers).id == supplier_company.id
    end

    test "renders errors when data is invalid", %{conn: conn, invalid_attrs: invalid_attrs} do
      conn = post conn, auction_path(conn, :create), auction: invalid_attrs

      assert conn.assigns[:auction] == struct(Auctions.Auction, invalid_attrs) |> Auctions.fully_loaded
      assert html_response(conn, 200) =~ "New Auction"
    end

    test "redirects to show when creating a draft auction", %{conn: conn, valid_auction_params: valid_auction_params} do
      draft_attrs = Map.drop(valid_auction_params, ["duration", "decision_duration", "fuel_id", "fuel_quantity"])
      conn = post conn, auction_path(conn, :create), auction: draft_attrs
      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == auction_path(conn, :show, id)
    end

    test "renders errors when adding auction_start without fuel details", %{conn: conn, valid_auction_params: valid_auction_params} do
      invalid_attrs = valid_auction_params
      |> Map.drop(["duration", "decision_duration", "fuel_id", "fuel_quantity"])
      |> Map.put("auction_start", DateTime.utc_now() |> DateTime.to_unix() |> Integer.to_string())
      conn = post conn, auction_path(conn, :create), auction: invalid_attrs

      assert html_response(conn, 200) =~ "New Auction"
    end
  end

  describe "start auction" do
    test "manually starting an auction", (%{auction: auction, conn: conn}) do
      new_conn = get(conn, auction_path(conn, :start, auction.id))

      assert redirected_to(new_conn, 302) == "/auctions"
    end
  end

  describe "show auction" do
    test "redirects to index unless user is a participant", %{auction: auction} do
      user = insert(:user)
      non_participant_conn = login_user(build_conn(), user)

      conn = get non_participant_conn, auction_path(non_participant_conn, :show, auction)
      assert redirected_to(conn, 302) == "/auctions"
    end
  end

  describe "edit auction" do
    test "redirects if current user is not buyer", %{supplier: supplier, auction: auction} do
      supplier_conn = login_user(build_conn(), supplier)
      conn = get supplier_conn, auction_path(supplier_conn, :edit, auction)
      assert redirected_to(conn, 302) == "/auctions"
    end

    test "renders form for editing chosen auction", %{conn: conn, auction: auction} do
      conn = get conn, auction_path(conn, :edit, auction)
      assert html_response(conn, 200) =~ "Edit Auction"
    end

    test "confirms buyer is not in supplier list", %{conn: conn, auction: auction} do
      conn = get conn, auction_path(conn, :edit, auction)
      refute conn.assigns.suppliers =~ auction.buyer.name
    end
  end

  describe "update auction" do
    test "redirects if current user is not buyer", %{supplier: supplier, auction: auction} do
      supplier_conn = login_user(build_conn(), supplier)
      |> put(auction_path(build_conn(), :update, auction), auction: @update_attrs)
      assert redirected_to(supplier_conn, 302) == "/auctions"
    end

    test "renders form for editing chosen auction", %{conn: conn, auction: auction} do
      conn = get conn, auction_path(conn, :edit, auction)
      assert html_response(conn, 200) =~ "Edit Auction"
    end

    test "redirects when data is valid", %{conn: conn, auction: auction} do
      conn = put(conn, auction_path(conn, :update, auction), auction: @update_attrs)
      assert redirected_to(conn) == auction_path(conn, :show, auction)

      conn = get conn, auction_path(conn, :show, auction)
      assert html_response(conn, 200) =~ "window.userToken"
    end

    test "renders errors when data is invalid", %{conn: conn, auction: auction} do
      conn = put(conn, auction_path(conn, :update, auction), auction: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Auction"
    end
  end

  describe "auction log" do
    setup(%{auction: auction}) do
      {:ok, _pid} = start_supervised({Oceanconnect.Auctions.AuctionSupervisor, {auction, %{handle_events: false}}})
      :ok
    end

    test "a supplier cannot view log", %{auction: auction, supplier: supplier} do
      auction
      |> Auctions.start_auction()
      |> Auctions.end_auction()

      conn = build_conn()
      |> login_user(supplier)
      |> get(auction_path(build_conn(), :log, auction))

      assert redirected_to(conn, 302) == "/auctions"
    end

    test "buyer cannot view log if :pending or :open", %{auction: auction, conn: authed_conn} do
      conn = authed_conn
      |> get(auction_path(build_conn(), :log, auction))

      assert redirected_to(conn, 302) == "/auctions"

      auction
      |> Auctions.start_auction()

      conn = authed_conn
      |> get(auction_path(build_conn(), :log, auction))

      assert redirected_to(conn, 302) == "/auctions"
    end

    test "a buyer can view log for an closed auction", %{auction: auction, conn: authed_conn} do
      auction
      |> Auctions.start_auction()
      |> Auctions.end_auction()

      conn = authed_conn
      |> get(auction_path(build_conn(), :log, auction))

      assert html_response(conn, 200)
    end
  end
end
