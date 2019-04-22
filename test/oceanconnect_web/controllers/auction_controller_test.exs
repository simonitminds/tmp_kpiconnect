defmodule OceanconnectWeb.AuctionControllerTest do
  use OceanconnectWeb.ConnCase

  alias Oceanconnect.Auctions

  @update_attrs %{"duration" => 15}
  @invalid_attrs %{"port_id" => nil}

  setup do
    buyer_company = insert(:company, is_supplier: true)
    buyer = insert(:user, company: buyer_company)
    buyer_vessels = insert_list(3, :vessel, company: buyer_company)
    selected_vessel = hd(buyer_vessels)
    fuels = insert_list(3, :fuel)
    selected_fuel = hd(fuels)
    supplier_company = insert(:company, is_supplier: true)
    supplier = insert(:user, company: supplier_company)
    port = insert(:port, companies: [buyer_company, supplier_company])

    auction_vessel_fuels = [
      build(:vessel_fuel, vessel: selected_vessel, fuel: selected_fuel, quantity: 1500),
      build(:vessel_fuel, vessel: List.last(buyer_vessels), fuel: selected_fuel, quantity: 1500)
    ]

    valid_start_time =
      DateTime.utc_now()
      |> DateTime.to_unix(:millisecond)
      |> Kernel.+(100_000)
      |> Integer.to_string()

    auction_params =
      string_params_for(
        :auction,
        auction_vessel_fuels: auction_vessel_fuels,
        port: port,
        is_traded_bid_allowed: true
      )
      |> Oceanconnect.Utilities.maybe_convert_date_times()
      |> Map.put("suppliers", %{"supplier-#{supplier_company.id}" => "#{supplier_company.id}"})
      |> Map.put("scheduled_start", valid_start_time)
      |> Map.put(
        "vessels",
        Enum.reduce(buyer_vessels, %{}, fn vessel, acc ->
          Map.put(acc, "#{vessel.id}", %{"eta" => valid_start_time})
        end)
      )
      |> Map.put("auction_vessel_fuels", %{
        "#{selected_fuel.id}" => %{
          "#{selected_vessel.id}" => 1500,
          "#{List.last(buyer_vessels).id}" => 1500
        }
      })

    authed_conn = login_user(build_conn(), buyer)

    auction =
      insert(
        :auction,
        port: port,
        buyer: buyer_company,
        auction_vessel_fuels: auction_vessel_fuels,
        suppliers: [supplier_company],
        is_traded_bid_allowed: true
      )
      |> Auctions.fully_loaded()

    {:ok,
     conn: authed_conn,
     valid_auction_params: auction_params,
     auction: auction,
     buyer: buyer_company,
     supplier: supplier,
     supplier_company: supplier_company,
     selected_vessel: selected_vessel,
     selected_fuel: selected_fuel}
  end

  describe "index" do
    test "lists all auctions", %{conn: conn} do
      conn = get(conn, auction_path(conn, :index))
      assert html_response(conn, 200)
    end
  end

  describe "new auction" do
    test "renders form", %{conn: conn} do
      conn = get(conn, auction_path(conn, :new))
      assert html_response(conn, 200) =~ "New Auction"
    end

    test "vessels are filtered by logged in buyers company", %{conn: conn, buyer: buyer} do
      conn = get(conn, auction_path(conn, :new))

      assert conn.assigns[:vessels] ==
               buyer
               |> Auctions.vessels_for_buyer()
               |> Auctions.strip_non_loaded()
               |> Poison.encode!()
    end
  end

  describe "create auction" do
    setup(%{buyer: buyer}) do
      invalid_attrs = Map.merge(@invalid_attrs, %{buyer_id: buyer.id})
      {:ok, %{invalid_attrs: invalid_attrs}}
    end

    test "redirects to show when data is valid", %{
      conn: conn,
      valid_auction_params: valid_auction_params,
      buyer: buyer,
      supplier_company: supplier_company,
      selected_vessel: selected_vessel,
      selected_fuel: selected_fuel
    } do
      updated_params =
        valid_auction_params
        |> Map.put("duration", round(valid_auction_params["duration"] / 60_000))
        |> Map.put("decision_duration", round(valid_auction_params["decision_duration"] / 60_000))

      conn = post(conn, auction_path(conn, :create), auction: updated_params)
      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == auction_path(conn, :show, id)

      auction = Oceanconnect.Repo.get(Auctions.Auction, id) |> Auctions.fully_loaded()
      conn = get(conn, auction_path(conn, :show, id))
      assert html_response(conn, 200) =~ "window.userToken"
      assert auction.buyer_id == buyer.id
      assert hd(auction.suppliers).id == supplier_company.id
      assert hd(auction.auction_vessel_fuels).vessel.id == selected_vessel.id
      assert hd(auction.auction_vessel_fuels).fuel.id == selected_fuel.id
    end

    test "renders errors when data is invalid", %{conn: conn, invalid_attrs: invalid_attrs} do
      conn = post(conn, auction_path(conn, :create), auction: invalid_attrs)

      assert conn.assigns[:auction] ==
               struct(Auctions.Auction, invalid_attrs) |> Auctions.fully_loaded()

      assert html_response(conn, 200) =~ "New Auction"
    end

    test "renders errors when creating a scheduled auction without inviting suppliers", %{conn: conn, valid_auction_params: valid_auction_params} do
      updated_params =
        valid_auction_params
        |> Map.put("duration", round(valid_auction_params["duration"] / 60_000))
        |> Map.put("decision_duration", round(valid_auction_params["decision_duration"] / 60_000))
        |> Map.put("suppliers", "")

      conn = post(conn, auction_path(conn, :create), auction: updated_params)

      assert html_response(conn, 200) =~ "Must invite suppliers to create a pending auction"
    end

    test "redirects to show when creating a draft auction", %{
      conn: conn,
      valid_auction_params: valid_auction_params
    } do
      draft_attrs =
        Map.drop(valid_auction_params, ["scheduled_start", "duration", "decision_duration"])

      conn = post(conn, auction_path(conn, :create), auction: draft_attrs)
      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == auction_path(conn, :show, id)
    end

    test "draft auctions can be updated and remain draft if pending requirements aren't met", %{
      conn: conn,
      valid_auction_params: valid_auction_params
    } do
      draft_attrs =
        Map.merge(valid_auction_params, %{
          "scheduled_start" => nil,
          "duration" => 0,
          "decision_duration" => 0
        })

      conn = post(conn, auction_path(conn, :create), auction: draft_attrs)

      auction =
        Oceanconnect.Repo.all(Auctions.Auction)
        |> Enum.reverse()
        |> hd()

      assert Auctions.get_auction_status!(auction) == :draft
      updated_info = "This is should be allowed to be updated."

      conn =
        put(conn, auction_path(conn, :update, auction.id),
          auction: %{draft_attrs | "additional_information" => updated_info}
        )

      assert html_response(conn, 302)
      assert redirected_to(conn) == auction_path(conn, :show, auction.id)

      :timer.sleep(500)

      auction = Auctions.get_auction(auction.id)

      assert Auctions.get_auction(auction.id).additional_information == updated_info
      assert Auctions.get_auction_status!(auction) == :draft
    end

    test "renders errors when adding scheduled_start without fuel details", %{
      conn: conn,
      valid_auction_params: valid_auction_params
    } do
      invalid_attrs =
        valid_auction_params
        |> Map.drop(["duration", "decision_duration", "auction_vessel_fuels"])
        |> Map.put(
          "scheduled_start",
          DateTime.utc_now() |> DateTime.to_unix() |> Integer.to_string()
        )

      conn = post(conn, auction_path(conn, :create), auction: invalid_attrs)

      assert html_response(conn, 200) =~ "New Auction"
    end
  end

  describe "cancel auction" do
    test "manually canceling an auction", %{conn: conn, auction: auction} do
      new_conn = get(conn, auction_path(conn, :cancel, auction.id))

      assert redirected_to(new_conn, 302) == "/auctions"
    end
  end

  describe "start auction" do
    test "manually starting an auction", %{auction: auction, conn: conn} do
      new_conn = get(conn, auction_path(conn, :start, auction.id))

      assert redirected_to(new_conn, 302) == "/auctions"
    end
  end

  describe "show auction" do
    test "redirects to index unless user is a participant", %{auction: auction} do
      user = insert(:user)
      non_participant_conn = login_user(build_conn(), user)

      conn = get(non_participant_conn, auction_path(non_participant_conn, :show, auction))
      assert redirected_to(conn, 302) == "/auctions"
    end
  end

  describe "edit auction" do
    test "redirects if current user is not buyer", %{supplier: supplier, auction: auction} do
      supplier_conn = login_user(build_conn(), supplier)
      conn = get(supplier_conn, auction_path(supplier_conn, :edit, auction))
      assert redirected_to(conn, 302) == "/auctions"
    end

    test "renders form for editing chosen auction", %{conn: conn, auction: auction} do
      conn = get(conn, auction_path(conn, :edit, auction))
      assert html_response(conn, 200) =~ "Edit Auction"
    end

    test "redirects if auction is in open or decision state", %{conn: conn, auction: auction} do
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

      Auctions.start_auction(auction)
      conn = get(conn, auction_path(conn, :edit, auction))
      assert redirected_to(conn, 302) == "/auctions"

      Auctions.end_auction(auction)
      conn = get(conn, auction_path(conn, :edit, auction))
      assert redirected_to(conn, 302) == "/auctions"
    end

    test "confirms buyer is not in supplier list", %{conn: conn, auction: auction} do
      conn = get(conn, auction_path(conn, :edit, auction))
      refute conn.assigns.suppliers =~ auction.buyer.name
    end
  end

  describe "update auction" do
    test "redirects if current user is not buyer", %{supplier: supplier, auction: auction} do
      supplier_conn =
        login_user(build_conn(), supplier)
        |> put(auction_path(build_conn(), :update, auction), auction: @update_attrs)

      assert redirected_to(supplier_conn, 302) == "/auctions"
    end

    test "redirects if auction in open or decision state", %{conn: conn, auction: auction} do
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

      Auctions.start_auction(auction)
      conn = put(conn, auction_path(conn, :update, auction), auction: @update_attrs)
      assert redirected_to(conn, 302) == "/auctions"

      Auctions.end_auction(auction)
      conn = put(conn, auction_path(conn, :update, auction), auction: @update_attrs)
      assert redirected_to(conn, 302) == "/auctions"
    end

    test "renders form for editing chosen auction", %{conn: conn, auction: auction} do
      conn = get(conn, auction_path(conn, :edit, auction))
      assert html_response(conn, 200) =~ "Edit Auction"
    end

    test "redirects when data is valid", %{
      conn: conn,
      auction: auction,
      valid_auction_params: valid_auction_params
    } do
      attrs =
        valid_auction_params
        |> Map.put("duration", round(valid_auction_params["duration"] / 60_000))
        |> Map.put("decision_duration", round(valid_auction_params["decision_duration"] / 60_000))
        |> Map.merge(@update_attrs)

      conn = put(conn, auction_path(conn, :update, auction), auction: attrs)
      assert redirected_to(conn) == auction_path(conn, :show, auction)

      conn = get(conn, auction_path(conn, :show, auction))
      assert html_response(conn, 200) =~ "window.userToken"
    end

    test "renders errors when data is invalid", %{conn: conn, auction: auction} do
      conn = put(conn, auction_path(conn, :update, auction), auction: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Auction"
    end
  end

  describe "auction log" do
    setup(%{auction: auction}) do
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

      :ok
    end

    test "a supplier cannot view log", %{auction: auction, supplier: supplier} do
      auction
      |> Auctions.start_auction()
      |> Auctions.end_auction()

      conn =
        build_conn()
        |> login_user(supplier)
        |> get(auction_path(build_conn(), :log, auction))

      assert redirected_to(conn, 302) == "/auctions"
    end

    test "buyer cannot view log if :pending or :open", %{auction: auction, conn: authed_conn} do
      conn =
        authed_conn
        |> get(auction_path(build_conn(), :log, auction))

      assert redirected_to(conn, 302) == "/auctions"

      auction
      |> Auctions.start_auction()

      conn =
        authed_conn
        |> get(auction_path(build_conn(), :log, auction))

      assert redirected_to(conn, 302) == "/auctions"
    end

    test "a buyer can view log for a closed auction", %{auction: auction, conn: authed_conn} do
      auction
      |> Auctions.start_auction()
      |> Auctions.end_auction()

      conn =
        authed_conn
        |> get(auction_path(build_conn(), :log, auction))

      assert html_response(conn, 200)
    end

    test "the log includes messages", %{auction: auction, conn: authed_conn} do
      insert_list(4, :message, auction: auction, author_company: auction.buyer)

      auction
      |> Auctions.start_auction()
      |> Auctions.end_auction()

      conn =
        authed_conn
        |> get(auction_path(build_conn(), :log, auction))

      assert length(Map.keys(conn.assigns.messages_by_company)) == 4
    end
  end
end
