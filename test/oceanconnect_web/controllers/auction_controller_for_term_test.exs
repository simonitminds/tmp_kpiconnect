defmodule OceanconnectWeb.AuctionControllerForTermTest do
  use OceanconnectWeb.ConnCase
  alias Oceanconnect.Auctions

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

    update_attrs = %{"duration" => 15, "type" => "forward_fixed"}
    invalid_attrs = %{"type" => "forward_fixed", "port_id" => nil, "buyer_id" => buyer.id}

    valid_start_time =
      DateTime.utc_now()
      |> DateTime.to_unix(:millisecond)
      |> Kernel.+(100_000)
      |> Integer.to_string()

    auction_params =
      string_params_for(
        :term_auction,
        port: port,
        is_traded_bid_allowed: true,
        start_date: valid_start_time,
        end_date: valid_start_time,
        fuel: selected_fuel
      )
      |> Oceanconnect.Utilities.maybe_convert_date_times()
      |> Map.put("suppliers", %{"supplier-#{supplier_company.id}" => "#{supplier_company.id}"})
      |> Map.put("scheduled_start", valid_start_time)
      |> Map.put(
        "vessels",
        Enum.reduce(buyer_vessels, %{}, fn vessel, acc ->
          Map.put_new(acc, "#{vessel.id}", %{"selected" => true})
        end)
      )

    authed_conn = login_user(build_conn(), buyer)

    auction =
      insert(
        :term_auction,
        port: port,
        buyer: buyer_company,
        suppliers: [supplier_company]
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
     selected_fuel: selected_fuel,
     update_attrs: update_attrs,
     invalid_attrs: invalid_attrs}
  end

  describe "create term auction" do
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

      auction = Oceanconnect.Repo.get(Auctions.TermAuction, id) |> Auctions.fully_loaded()
      conn = get(conn, auction_path(conn, :show, id))
      assert html_response(conn, 200) =~ "window.userToken"
      assert auction.buyer_id == buyer.id
      assert hd(auction.suppliers).id == supplier_company.id
      assert auction.fuel.id == selected_fuel.id
      assert hd(auction.vessels).id == selected_vessel.id
    end

    test "renders errors when data is invalid", %{conn: conn, invalid_attrs: invalid_attrs} do
      conn = post(conn, auction_path(conn, :create), auction: invalid_attrs)
      assert Enum.any?(conn.assigns[:changeset].errors), "expected errors but got none"

      assert conn.assigns[:changeset].errors == [
               port_id: {"can't be blank", [validation: :required]},
               fuel_id: {"can't be blank", [validation: :required]}
             ]

      assert html_response(conn, 200) =~ "New Auction"
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
      auction = Oceanconnect.Repo.get(Auctions.TermAuction, id)
      status = Auctions.get_auction_status!(auction)
      assert status == :draft
    end

    test "draft auctions can be updated and remain draft if pending requirements aren't met", %{
      conn: conn,
      valid_auction_params: valid_auction_params
    } do
      draft_attrs =
        draft_attrs =
        Map.merge(valid_auction_params, %{
          "scheduled_start" => nil,
          "duration" => 0,
          "decision_duration" => 0
        })

      conn = post(conn, auction_path(conn, :create), auction: draft_attrs)
      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == auction_path(conn, :show, id)

      auction = Oceanconnect.Repo.get(Auctions.TermAuction, id)
      status = Auctions.get_auction_status!(auction)
      assert status == :draft
      updated_info = "This should be allowed to be updated."

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
        |> Map.merge(%{"fuel_id" => nil})

      conn = post(conn, auction_path(conn, :create), auction: invalid_attrs)

      assert html_response(conn, 200) =~ "New Auction"

      assert conn.assigns.changeset.errors == [
               fuel_id: {"This field is required.", [validation: :required]}
             ]
    end
  end

  describe "cancel term auction" do
    test "manually canceling an auction", %{conn: conn, auction: auction} do
      new_conn = get(conn, auction_path(conn, :cancel, auction.id))

      assert redirected_to(new_conn, 302) == "/auctions"
    end
  end

  describe "start term auction" do
    test "manually starting an auction", %{auction: auction} do
      {:ok, _pid} =
        start_supervised(
          {Oceanconnect.Auctions.AuctionSupervisor,
           {auction,
            %{
              exclude_children: [
                :auction_event_handler,
                :auction_scheduler
              ]
            }}}
        )

      admin = insert(:user, is_admin: true)
      authed_conn = login_user(build_conn(), admin)
      new_conn = get(authed_conn, auction_path(authed_conn, :start, auction.id))

      assert redirected_to(new_conn, 302) == "/auctions"
      :timer.sleep(500)
      assert Auctions.get_auction_status!(auction) == :open
    end
  end

  describe "show term auction" do
    test "redirects to index unless user is a participant", %{auction: auction} do
      user = insert(:user)
      non_participant_conn = login_user(build_conn(), user)

      conn = get(non_participant_conn, auction_path(non_participant_conn, :show, auction))
      assert redirected_to(conn, 302) == "/auctions"
    end
  end

  describe "edit term auction" do
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

  describe "update term auction" do
    test "redirects if current user is not buyer", %{
      supplier: supplier,
      auction: auction,
      update_attrs: update_attrs
    } do
      supplier_conn =
        login_user(build_conn(), supplier)
        |> put(auction_path(build_conn(), :update, auction), auction: update_attrs)

      assert redirected_to(supplier_conn, 302) == "/auctions"
    end

    test "redirects if auction in open or decision state", %{
      conn: conn,
      auction: auction,
      update_attrs: update_attrs
    } do
      {:ok, _pid} =
        start_supervised(
          {Oceanconnect.Auctions.AuctionSupervisor,
           {auction,
            %{
              exclude_children: [
                :auction_event_handler,
                :auction_scheduler
              ]
            }}}
        )

      Auctions.start_auction(auction)
      conn = put(conn, auction_path(conn, :update, auction), auction: update_attrs)
      assert redirected_to(conn, 302) == "/auctions"

      Auctions.end_auction(auction)
      conn = put(conn, auction_path(conn, :update, auction), auction: update_attrs)
      assert redirected_to(conn, 302) == "/auctions"
    end

    test "renders form for editing chosen auction", %{conn: conn, auction: auction} do
      conn = get(conn, auction_path(conn, :edit, auction))
      assert html_response(conn, 200) =~ "Edit Auction"
    end

    test "redirects when data is valid", %{
      conn: conn,
      auction: auction,
      valid_auction_params: valid_auction_params,
      update_attrs: update_attrs
    } do
      attrs =
        valid_auction_params
        |> Map.put("duration", round(valid_auction_params["duration"] / 60_000))
        |> Map.put("decision_duration", round(valid_auction_params["decision_duration"] / 60_000))
        |> Map.merge(update_attrs)

      conn = put(conn, auction_path(conn, :update, auction), auction: attrs)
      assert redirected_to(conn) == auction_path(conn, :show, auction)

      conn = get(conn, auction_path(conn, :show, auction))
      assert html_response(conn, 200) =~ "window.userToken"
    end

    test "renders errors when data is invalid", %{
      conn: conn,
      auction: auction,
      invalid_attrs: invalid_attrs
    } do
      conn = put(conn, auction_path(conn, :update, auction), auction: invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Auction"
    end
  end

  describe "term auction log" do
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
      # THIS IS GROSS but MESSAGES DOESN't KNOW ABOUT TERM
      auction =
        Oceanconnect.Repo.get(Auctions.Auction, auction.id)
        |> Auctions.fully_loaded()

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
