defmodule Oceanconnect.AuctionsTest do
  use Oceanconnect.DataCase

  alias Oceanconnect.Auctions

  describe "auctions" do
    alias Oceanconnect.Auctions.Auction

    @invalid_attrs %{vessel_id: nil}
    @valid_attrs %{po: "some po"}
    @update_attrs %{po: "some updated po"}

    setup do
      auction = insert(:auction, @valid_attrs)
      {:ok, %{auction: Auctions.get_auction!(auction.id)}}
    end

    test "#maybe_parse_date_field" do
      expected_date = DateTime.from_naive!(~N[2017-12-28 01:30:00.000], "Etc/UTC")
      epoch = expected_date
      |> DateTime.to_unix(:milliseconds)
      |> Integer.to_string
      params = %{"auction_start" => epoch}
      %{ "auction_start" => parsed_date } = Auction.maybe_parse_date_field(params, "auction_start")

      assert parsed_date == expected_date |> DateTime.to_string()
    end

    test "#maybe_convert_duration" do
      params = %{"duration" => "10", "decision_duration" => "15"}
      %{ "duration" => duration } = Auction.maybe_convert_duration(params, "duration")
      %{ "decision_duration" => decision_duration } = Auction.maybe_convert_duration(params, "decision_duration")

      assert duration == 10 * 60_000
      assert decision_duration == 15 * 60_000
    end

    test "#maybe_load_suppliers" do
      supplier = insert(:company, is_supplier: true)
      params = %{"suppliers" => %{"supplier-#{supplier.id}" => "#{supplier.id}"}}
      %{ "suppliers" => suppliers } = Auction.maybe_load_suppliers(params, "suppliers")

      assert List.first(suppliers).id == supplier.id
    end

    test "list_auctions/0 returns all auctions", %{auction: auction} do
      assert Auctions.list_auctions()
      |> Enum.map(fn(a) -> a.id end)
      |> MapSet.new
      |> MapSet.equal?(MapSet.new([auction.id]))
    end

    test "list_participating_auctions/1 returns all auctions a company is a participant in", %{auction: auction} do
      supplier_auction = insert(:auction, suppliers: [Repo.preload(auction, [:buyer]).buyer])
      insert(:auction)
      assert Auctions.list_participating_auctions(auction.buyer_id)
      |> Enum.map(fn(a) -> a.id end)
      |> MapSet.new
      |> MapSet.equal?(MapSet.new([auction.id, supplier_auction.id]))
    end

    test "list_participating_auctions/1 doesn't return draft auctions" do
      supplier_company = insert(:company, is_supplier: true)
      insert(:auction, auction_start: nil, suppliers: [supplier_company])
      assert Auctions.list_participating_auctions(supplier_company.id) == []
    end

    test "list_participating_auctions/1 orders on auction_start" do
      supplier_company = insert(:company, is_supplier: true)

      {:ok, first_date, _} = DateTime.from_iso8601("2018-01-01T00:00:00Z")
      {:ok, second_date, _} = DateTime.from_iso8601("2018-01-02T00:00:00Z")
      {:ok, third_date, _} = DateTime.from_iso8601("2018-01-03T00:00:00Z")
      {:ok, fourth_date, _} = DateTime.from_iso8601("2018-01-04T00:00:00Z")

      auction_one = insert(:auction, auction_start: third_date, suppliers: [supplier_company])
      auction_two = insert(:auction, auction_start: first_date, suppliers: [supplier_company])
      auction_three = insert(:auction, auction_start: second_date, suppliers: [supplier_company])
      auction_four = insert(:auction, auction_start: fourth_date, buyer: supplier_company)
      auction_five = insert(:auction, auction_start: third_date, buyer: supplier_company)
      auction_six = insert(:auction, auction_start: first_date, buyer: supplier_company)
      auctions = Enum.map(Auctions.list_participating_auctions(supplier_company.id), fn(a) -> a.id end)

      assert  [auction_six.id, auction_five.id, auction_four.id, auction_two.id, auction_three.id, auction_one.id] == auctions
    end

    test "get_auction!/1 returns the auction with given id", %{auction: auction} do
      assert Auctions.get_auction!(auction.id) == auction
    end

    test "create_auction/1 with valid data creates a auction", %{auction: auction} do
      auction_with_participants = Auctions.with_participants(auction)
      auction_attrs = auction_with_participants |> Map.take([:auction_start, :eta, :fuel_id, :port_id, :vessel_id, :suppliers] ++ Map.keys(@valid_attrs))
      assert {:ok, %Auction{} = new_auction} = Auctions.create_auction(auction_attrs)

      assert all_values_match?(auction_attrs, new_auction)

      supplier = hd(auction_with_participants.suppliers)
      auction_supplier = Repo.get_by(Auctions.AuctionSuppliers, %{auction_id: new_auction.id, supplier_id: supplier.id})
      assert auction_supplier.alias_name == "Supplier 1"
    end

    test "create_auction/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Auctions.create_auction(@invalid_attrs)
    end

    test "update_auction_without_event_storage!/2 with valid data updates the auction", %{auction: auction} do
      assert auction = %Auction{} = Auctions.update_auction_without_event_storage!(auction, @update_attrs)
      assert auction.po == "some updated po"
    end

    test "update_auction!/3 with valid data updates the auction", %{auction: auction} do
      assert auction = %Auction{} = Auctions.update_auction!(auction, @update_attrs, nil)
      assert auction.po == "some updated po"
    end

    test "update_auction/3 with valid data updates the auction", %{auction: auction} do
      assert {:ok, auction} = Auctions.update_auction(auction, @update_attrs, nil)
      assert %Auction{} = auction
      assert auction.po == "some updated po"
    end

    test "update_auction/3 with invalid data returns error changeset", %{auction: auction} do
      assert {:error, %Ecto.Changeset{}} = Auctions.update_auction(auction, @invalid_attrs, nil)
      assert auction == Auctions.get_auction!(auction.id)
    end

    test "delete_auction/1 deletes the auction", %{auction: auction} do
      assert {:ok, %Auction{}} = Auctions.delete_auction(auction)
      assert_raise Ecto.NoResultsError, fn -> Auctions.get_auction!(auction.id) end
    end

    test "change_auction/1 returns a auction changeset", %{auction: auction} do
      assert %Ecto.Changeset{} = Auctions.change_auction(auction)
    end
  end

  describe "ending an auction" do
    alias Oceanconnect.Auctions.{Auction, AuctionSupervisor, AuctionEventStore}

    setup do
      supplier_company = insert(:company)
      supplier2_company = insert(:company)
      auction = insert(:auction, duration: 1_000, decision_duration: 1_000, suppliers: [supplier_company, supplier2_company])

      {:ok, _pid} = start_supervised({AuctionSupervisor, {auction, %{handle_events: true}}})
      on_exit(fn ->
        case DynamicSupervisor.which_children(Oceanconnect.Auctions.AuctionsSupervisor) do
          [] -> nil
          children ->
            Enum.map(children, fn({_, pid, _, _}) ->
              Process.unlink(pid)
              Process.exit(pid, :shutdown)
            end)
        end
      end)

      {:ok, %{auction: auction}}
    end

    test "ending an auction saves the auction_ended timestamp on the auction", %{auction: auction = %Auction{id: auction_id}} do
      auction
      |> Auctions.start_auction
      |> Auctions.end_auction
      :timer.sleep(500)

      auction_ended_event = auction_id
      |> AuctionEventStore.event_list
      |> Enum.filter(fn(event) -> event.type == :auction_ended end)
      |> hd

      updated_auction = Auctions.get_auction(auction_id)
      assert auction_ended_event.time_entered == updated_auction.auction_ended
    end
  end

  describe "bid handling" do
    alias Oceanconnect.Auctions.AuctionBidList

    setup do
      supplier_company = insert(:company, is_supplier: true)
      auction = insert(:auction, suppliers: [supplier_company])
      {:ok, _pid} = start_supervised({Auctions.AuctionSupervisor, {auction, %{handle_events: false}}})
      Auctions.start_auction(auction)
      on_exit(fn ->
        case DynamicSupervisor.which_children(Oceanconnect.Auctions.AuctionsSupervisor) do
          [] -> nil
          children ->
            Enum.map(children, fn({_, pid, _, _}) ->
              Process.unlink(pid)
              Process.exit(pid, :shutdown)
            end)
        end
      end)

      {:ok, %{auction: auction, supplier_company: supplier_company}}
    end

    test "place_bid/3 enters bid in bid_list and runs lowest_bid logic", %{auction: auction, supplier_company: supplier_company} do
      amount = 1.25
      expected_result = %{
        amount: amount,
        auction_id: auction.id,
        supplier_id: supplier_company.id,
        time_entered: DateTime.utc_now()
      }

      assert bid = %AuctionBidList.AuctionBid{} = Auctions.place_bid(auction, %{"amount" => amount}, supplier_company.id)
      assert Enum.all?(expected_result, fn({k, v}) ->
        if k == :time_entered do
          Map.fetch!(bid, k) >= v
        else
          Map.fetch!(bid, k) == v
        end
      end)
      payload = Auctions.AuctionPayload.get_auction_payload!(auction, supplier_company.id)

      assert hd(payload.bid_list).id == bid.id
      assert hd(payload.state.lowest_bids).id == bid.id
    end
  end

  describe "ports" do
    alias Oceanconnect.Auctions.Port

    @valid_attrs %{name: "some port", country: "Merica"}
    @update_attrs %{name: "some updated port", country: "Merica"}
    @invalid_attrs %{name: nil, country: "Merica"}

    setup do
      port = insert(:port, @valid_attrs)
      {:ok, %{port: Auctions.get_port!(port.id)}}
    end

    test "list_ports/0 returns all ports", %{port: port} do
      assert Auctions.list_ports() == [port]
    end

    test "get_port!/1 returns the port with given id", %{port: port} do
      assert Auctions.get_port!(port.id) == port
    end

    test "create_port/1 with valid data creates a port" do
      assert {:ok, %Port{} = port} = Auctions.create_port(@valid_attrs)
      assert all_values_match?(@valid_attrs, port)
    end

    test "create_port/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Auctions.create_port(@invalid_attrs)
    end

    test "update_port/2 with valid data updates the port", %{port: port} do
      assert {:ok, port} = Auctions.update_port(port, @update_attrs)
      assert %Port{} = port
      assert all_values_match?(@update_attrs, port)
    end

    test "update_port/2 with invalid data returns error changeset", %{port: port} do
      assert {:error, %Ecto.Changeset{}} = Auctions.update_port(port, @invalid_attrs)
      assert port == Auctions.get_port!(port.id)
    end

    test "delete_port/1 deletes the port", %{port: port} do
      assert {:ok, %Port{}} = Auctions.delete_port(port)
      assert_raise Ecto.NoResultsError, fn -> Auctions.get_port!(port.id) end
    end

    test "change_port/1 returns a port changeset", %{port: port} do
      assert %Ecto.Changeset{} = Auctions.change_port(port)
    end
  end

  describe "port and company relationship" do
    setup do
      [port1, port2] = insert_list(2, :port)
      [company1, company2, company3] = insert_list(3, :company, is_supplier: true)
      company4 = insert(:company)
      company1 |> Oceanconnect.Accounts.add_port_to_company(port1)
      company2 |> Oceanconnect.Accounts.set_ports_on_company([port1, port2])
      company3 |> Oceanconnect.Accounts.add_port_to_company(port2)
      company4 |> Oceanconnect.Accounts.add_port_to_company(port1)
      {:ok, %{p1: port1, p2: port2, c1: company1, c2: company2, c3: company3}}
    end

    test "supplier_list_for_auction/1 returns only supplier companies for given port", %{p1: p1, p2: p2, c1: c1, c2: c2, c3: c3} do
      companies = Auctions.supplier_list_for_auction(p1)
      assert Enum.all?(companies, fn(c) -> c.id in [c1.id, c2.id] end)
      assert length(companies) == 2
      assert Enum.all?(Auctions.supplier_list_for_auction(p2), fn(c) -> c.id in [c2.id, c3.id] end)
    end

    test "supplier_list_for_auction/2 returns only supplier companies for given port and not buyer", %{p1: p1, c1: buyer, c2: c2} do
      companies = Auctions.supplier_list_for_auction(p1, buyer.id)
      assert length(companies) == 1
      assert hd(companies).id == c2.id
    end

    test "ports_for_company/1 returns ports for given company", %{p1: p1, p2: p2, c1: c1, c2: c2} do
      ports = Auctions.ports_for_company(c2)
      assert Enum.all?(ports, fn(p) -> p.id in [p1.id, p2.id] end)
      assert length(ports) == 2
      assert Enum.all?(Auctions.ports_for_company(c1), fn(p) -> p.id === p1.id end)
    end
  end

  describe "vessels" do
    alias Oceanconnect.Auctions.Vessel

    @valid_attrs %{imo: 42, name: "some name"}
    @update_attrs %{imo: 43, name: "some updated name"}
    @invalid_attrs %{imo: nil, name: nil}

    setup do
      company = insert(:company)
      vessel = insert(:vessel, Map.merge(@valid_attrs, %{company: company}))
      user = insert(:user, company: company)
      {:ok, %{company: company, user: user, vessel: Auctions.get_vessel!(vessel.id)}}
    end

    test "vessels_for_buyer/1", %{user: user, vessel: vessel} do
      extra_vessel = insert(:vessel)
      result = Auctions.vessels_for_buyer(user.company)
      |> Oceanconnect.Repo.preload(:company)
      assert result == [vessel]
      refute extra_vessel in result
    end

    test "list_vessels/0 returns all vessels", %{vessel: vessel} do
      assert Auctions.list_vessels() |> Repo.preload(:company) == [vessel]
    end

    test "get_vessel!/1 returns the vessel with given id", %{vessel: vessel} do
      assert Auctions.get_vessel!(vessel.id) == vessel
    end

    test "create_vessel/1 with valid data creates a vessel", %{company: company} do
      attrs = Map.merge(@valid_attrs, %{company_id: company.id})
      assert {:ok, %Vessel{} = vessel} = Auctions.create_vessel(attrs)
      assert all_values_match?(@valid_attrs, vessel)
    end

    test "create_vessel/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Auctions.create_vessel(@invalid_attrs)
    end

    test "update_vessel/2 with valid data updates the vessel", %{vessel: vessel} do
      assert {:ok, vessel} = Auctions.update_vessel(vessel, @update_attrs)
      assert %Vessel{} = vessel
      assert all_values_match?(@update_attrs, vessel)
    end

    test "update_vessel/2 with invalid data returns error changeset", %{ vessel: vessel} do
      assert {:error, %Ecto.Changeset{}} = Auctions.update_vessel(vessel, @invalid_attrs)
      assert vessel == Auctions.get_vessel!(vessel.id)
    end

    test "delete_vessel/1 deletes the vessel", %{vessel: vessel} do
      assert {:ok, %Vessel{}} = Auctions.delete_vessel(vessel)
      assert_raise Ecto.NoResultsError, fn -> Auctions.get_vessel!(vessel.id) end
    end

    test "change_vessel/1 returns a vessel changeset", %{vessel: vessel} do
      assert %Ecto.Changeset{} = Auctions.change_vessel(vessel)
    end
  end

  describe "fuels" do
    alias Oceanconnect.Auctions.Fuel

    @valid_attrs %{name: "some name"}
    @update_attrs %{name: "some updated name"}
    @invalid_attrs %{name: nil}

    setup do
      fuel = insert(:fuel, @valid_attrs)
      {:ok, %{fuel: Auctions.get_fuel!(fuel.id)}}
    end

    test "list_fuels/0 returns all fuels", %{fuel: fuel} do
      assert Enum.map(Auctions.list_fuels(), fn(f) -> f.id end) == [fuel.id]
    end

    test "get_fuel!/1 returns the fuel with given id", %{fuel: fuel} do
      assert Auctions.get_fuel!(fuel.id) == fuel
    end

    test "create_fuel/1 with valid data creates a fuel" do
      assert {:ok, %Fuel{} = fuel} = Auctions.create_fuel(@valid_attrs)
      assert fuel.name == "some name"
    end

    test "create_fuel/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Auctions.create_fuel(@invalid_attrs)
    end

    test "update_fuel/2 with valid data updates the fuel", %{fuel: fuel} do
      assert {:ok, fuel} = Auctions.update_fuel(fuel, @update_attrs)
      assert %Fuel{} = fuel
      assert fuel.name == "some updated name"
    end

    test "update_fuel/2 with invalid data returns error changeset", %{fuel: fuel} do
      assert {:error, %Ecto.Changeset{}} = Auctions.update_fuel(fuel, @invalid_attrs)
      assert fuel == Auctions.get_fuel!(fuel.id)
    end

    test "delete_fuel/1 deletes the fuel", %{fuel: fuel} do
      assert {:ok, %Fuel{}} = Auctions.delete_fuel(fuel)
      assert_raise Ecto.NoResultsError, fn -> Auctions.get_fuel!(fuel.id) end
    end

    test "change_fuel/1 returns a fuel changeset", %{fuel: fuel} do
      assert %Ecto.Changeset{} = Auctions.change_fuel(fuel)
    end
  end

  test "strip non loaded" do
    auction = insert(:auction)
    partially_loaded_auction = Oceanconnect.Auctions.Auction
    |> Repo.get(auction.id)
    |> Repo.preload([:vessel])

    result = Auctions.strip_non_loaded(partially_loaded_auction)
    assert result.vessel.company == nil
  end
end
