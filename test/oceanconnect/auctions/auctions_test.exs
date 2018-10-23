defmodule Oceanconnect.AuctionsTest do
  use Oceanconnect.DataCase

  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{Auction, AuctionSupervisor, AuctionEventStore}
  alias Oceanconnect.Auctions.AuctionStore.{AuctionState}

  describe "auctions" do
    alias Oceanconnect.Auctions.Auction

    @invalid_attrs %{port_id: "not a valid attribute"}
    @valid_attrs %{po: "some po"}
    @update_attrs %{po: "some updated po"}

    setup do
      auction = insert(:auction, @valid_attrs)
      |> Auctions.fully_loaded
      port = insert(:port)
      vessel = insert(:vessel)
      fuel = insert(:fuel)
      {:ok, %{auction: Auctions.get_auction!(auction.id), port: port, vessel: vessel, fuel: fuel}}
    end

    test "#maybe_parse_date_field" do
      expected_date = DateTime.from_naive!(~N[2017-12-28 01:30:00.000], "Etc/UTC")

      epoch =
        expected_date
        |> DateTime.to_unix(:milliseconds)
        |> Integer.to_string()

      params = %{"scheduled_start" => epoch}

      %{"scheduled_start" => parsed_date} =
        Auction.maybe_parse_date_field(params, "scheduled_start")

      assert parsed_date == expected_date |> DateTime.to_string()
    end

    test "#maybe_convert_duration" do
      params = %{"duration" => "10", "decision_duration" => "15"}
      %{"duration" => duration} = Auction.maybe_convert_duration(params, "duration")

      %{"decision_duration" => decision_duration} =
        Auction.maybe_convert_duration(params, "decision_duration")

      assert duration == 10 * 60_000
      assert decision_duration == 15 * 60_000
    end

    test "#maybe_load_suppliers" do
      supplier = insert(:company, is_supplier: true)
      params = %{"suppliers" => %{"supplier-#{supplier.id}" => "#{supplier.id}"}}
      %{"suppliers" => suppliers} = Auction.maybe_load_suppliers(params, "suppliers")

      assert List.first(suppliers).id == supplier.id
    end

    test "#maybe_add_vessel_fuels does not require quantity for draft auctions", %{port: port, vessel: vessel, fuel: fuel} do
      params = %{
        "port_id" => port.id,
        "eta" => DateTime.utc_now(),
        "scheduled_start" => nil,
        "auction_vessel_fuels" => [
          %{"vessel_id" => vessel.id, "fuel_id" => fuel.id, "quantity" => nil}
        ]
      }

      changeset = Auction.changeset(%Auction{}, params)
      assert changeset.valid?
    end

    test "#maybe_add_vessel_fuels is valid with just vessel_ids for draft auctions", %{port: port, vessel: vessel} do
      params = %{
        "port_id" => port.id,
        "eta" => DateTime.utc_now(),
        "scheduled_start" => nil,
        "auction_vessel_fuels" => [
          %{"vessel_id" => vessel.id}
        ]
      }

      changeset = Auction.changeset(%Auction{}, params)
      assert changeset.valid?
    end

    test "#maybe_add_vessel_fuels is valid with just fuel_ids for draft auctions", %{port: port, fuel: fuel} do
      params = %{
        "port_id" => port.id,
        "eta" => DateTime.utc_now(),
        "scheduled_start" => nil,
        "auction_vessel_fuels" => [
          %{"fuel_id" => fuel.id}
        ]
      }

      changeset = Auction.changeset(%Auction{}, params)
      assert changeset.valid?
    end

    test "#maybe_add_vessel_fuels is invalid without fuel quantities for scheduled auctions", %{port: port, vessel: vessel, fuel: fuel} do
      params = %{
        "port_id" => port.id,
        "eta" => DateTime.utc_now(),
        "scheduled_start" => DateTime.utc_now(),
        "auction_vessel_fuels" => [
          %{"vessel_id" => vessel.id, "fuel_id" => fuel.id, "quantity" => nil}
        ]
      }

      changeset = Auction.changeset(%Auction{}, params)
      refute changeset.valid?
    end

    test "#maybe_add_vessel_fuels is invalid without vessel ids for scheduled auctions", %{port: port, fuel: fuel} do
      params = %{
        "port_id" => port.id,
        "eta" => DateTime.utc_now(),
        "scheduled_start" => DateTime.utc_now(),
        "auction_vessel_fuels" => [
          %{"vessel_id" => nil, "fuel_id" => fuel.id, "quantity" => 1500}
        ]
      }

      changeset = Auction.changeset(%Auction{}, params)
      refute changeset.valid?
    end

    test "#maybe_add_vessel_fuels is invalid without fuel ids for scheduled auctions", %{port: port, vessel: vessel} do
      params = %{
        "port_id" => port.id,
        "eta" => DateTime.utc_now(),
        "scheduled_start" => DateTime.utc_now(),
        "auction_vessel_fuels" => [
          %{"vessel_id" => vessel.id, "fuel_id" => nil, "quantity" => 1500}
        ]
      }

      changeset = Auction.changeset(%Auction{}, params)
      refute changeset.valid?
    end

    test "#maybe_add_vessel_fuels is valid with fuel quantities for scheduled auctions", %{port: port, vessel: vessel, fuel: fuel} do
      params = %{
        "port_id" => port.id,
        "eta" => DateTime.utc_now(),
        "scheduled_start" => DateTime.utc_now(),
        "auction_vessel_fuels" => [
          %{"vessel_id" => vessel.id, "fuel_id" => fuel.id, "quantity" => 1500}
        ]
      }

      changeset = Auction.changeset(%Auction{}, params)
      assert changeset.valid?
    end

    test "list_auctions/0 returns all auctions", %{auction: auction} do
      assert Auctions.list_auctions()
             |> Enum.map(fn a -> a.id end)
             |> MapSet.new()
             |> MapSet.equal?(MapSet.new([auction.id]))
    end

    test "list_participating_auctions/1 returns all auctions a company is a participant in", %{
      auction: auction
    } do
      supplier_auction = insert(:auction, suppliers: [Repo.preload(auction, [:buyer]).buyer])
      insert(:auction)

      assert Auctions.list_participating_auctions(auction.buyer_id)
             |> Enum.map(fn a -> a.id end)
             |> MapSet.new()
             |> MapSet.equal?(MapSet.new([auction.id, supplier_auction.id]))
    end

    test "list_participating_auctions/1 doesn't return draft auctions" do
      supplier_company = insert(:company, is_supplier: true)
      insert(:auction, scheduled_start: nil, suppliers: [supplier_company])
      assert Auctions.list_participating_auctions(supplier_company.id) == []
    end

    test "list_participating_auctions/1 orders on scheduled_start" do
      supplier_company = insert(:company, is_supplier: true)

      {:ok, first_date, _} = DateTime.from_iso8601("2018-01-01T00:00:00Z")
      {:ok, second_date, _} = DateTime.from_iso8601("2018-01-02T00:00:00Z")
      {:ok, third_date, _} = DateTime.from_iso8601("2018-01-03T00:00:00Z")
      {:ok, fourth_date, _} = DateTime.from_iso8601("2018-01-04T00:00:00Z")

      auction_one = insert(:auction, scheduled_start: third_date, suppliers: [supplier_company])
      auction_two = insert(:auction, scheduled_start: first_date, suppliers: [supplier_company])

      auction_three =
        insert(:auction, scheduled_start: second_date, suppliers: [supplier_company])

      auction_four = insert(:auction, scheduled_start: fourth_date, buyer: supplier_company)
      auction_five = insert(:auction, scheduled_start: third_date, buyer: supplier_company)
      auction_six = insert(:auction, scheduled_start: first_date, buyer: supplier_company)

      auctions =
        Enum.map(Auctions.list_participating_auctions(supplier_company.id), fn a -> a.id end)

      assert [
               auction_six.id,
               auction_five.id,
               auction_four.id,
               auction_two.id,
               auction_three.id,
               auction_one.id
             ] == auctions
    end

    test "get_auction!/1 returns the auction with given id", %{auction: auction} do
      assert Auctions.get_auction!(auction.id) == auction
    end

    test "create_auction/1 with valid data creates a auction", %{auction: auction} do
      auction_with_participants = Auctions.with_participants(auction)
      |> Auctions.fully_loaded

      auction_attrs =
        auction_with_participants
        |> Map.take(
          [:scheduled_start, :eta, :port_id, :suppliers, :buyer_id, :auction_vessel_fuels] ++
            Map.keys(@valid_attrs)
        )
      assert {:ok, %Auction{} = new_auction} = Auctions.create_auction(auction_attrs)
      # create_auction has a side effect of starting the AuctionsSupervisor, thus the sleep
      :timer.sleep(200)

      assert all_values_match?(Map.drop(auction_attrs, [:auction_vessel_fuels]), new_auction)

      supplier = hd(auction_with_participants.suppliers)

      auction_supplier =
        Repo.get_by(Auctions.AuctionSuppliers, %{
          auction_id: new_auction.id,
          supplier_id: supplier.id
        })

      assert auction_supplier.alias_name == "Supplier 1"
    end

    test "create_auction/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Auctions.create_auction(@invalid_attrs)
    end

    test "update_auction_without_event_storage!/2 with valid data updates the auction", %{
      auction: auction
    } do
      assert auction =
               %Auction{} = Auctions.update_auction_without_event_storage!(auction, @update_attrs)

      assert auction.po == "some updated po"
      assert auction == Auctions.get_auction(auction.id)
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

  describe "canceling an auction" do
    setup do
      buyer_company = insert(:company)
      buyer = insert(:user, company: buyer_company)

      auction =
        insert(:auction, duration: 1_000, decision_duration: 1_000, buyer: buyer_company)
        |> Auctions.fully_loaded()

      {:ok, _pid} =
        start_supervised(
          {AuctionSupervisor,
           {auction, %{exclude_children: [:auction_reminder_timer, :auction_scheduler]}}}
        )

      {:ok, %{auction: auction, buyer: buyer}}
    end

    test "cancel_auction/1", %{auction: auction, buyer: buyer} do
      Auctions.cancel_auction(auction, buyer)
      # TODO: Eventually shutdown the auction and commit the final state
      # assert {:error, "Auciton Suppervisor Not Started"} = Auctions.AuctionSupervisor.find_pid(auction.id)
      assert %AuctionState{status: :canceled} = Auctions.get_auction_state!(auction)
    end
  end

  describe "ending an auction" do
    setup do
      supplier_company = insert(:company)
      supplier2_company = insert(:company)
      buyer_company = insert(:company, is_supplier: false)

      auction =
        insert(
          :auction,
          duration: 1_000,
          decision_duration: 1_000,
          suppliers: [supplier_company, supplier2_company],
          buyer: buyer_company
        )
        |> Auctions.fully_loaded()

      {:ok, _pid} =
        start_supervised(
          {AuctionSupervisor,
           {auction, %{exclude_children: [:auction_reminder_timer, :auction_scheduler]}}}
        )

      {:ok, %{auction: auction}}
    end

    test "ending an auction saves the auction_ended timestamp on the auction", %{
      auction: auction = %Auction{id: auction_id}
    } do
      auction
      |> Auctions.start_auction()
      |> Auctions.end_auction()

      :timer.sleep(500)

      auction_ended_event =
        auction_id
        |> AuctionEventStore.event_list()
        |> Enum.filter(fn event -> event.type == :auction_ended end)
        |> hd

      updated_auction = Auctions.get_auction(auction_id)
      assert auction_ended_event.time_entered == updated_auction.auction_ended
    end
  end

  describe "bid handling" do
    alias Oceanconnect.Auctions.AuctionBid

    setup do
      supplier_company = insert(:company, is_supplier: true)
      buyer_company = insert(:company, is_supplier: false)
      fuel = insert(:fuel)
      fuel_id = "#{fuel.id}"

      auction =
        insert(:auction, suppliers: [supplier_company], buyer: buyer_company, auction_vessel_fuels: [build(:vessel_fuel, fuel: fuel)])
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

      Auctions.start_auction(auction)

      on_exit(fn ->
        case DynamicSupervisor.which_children(Oceanconnect.Auctions.AuctionsSupervisor) do
          [] ->
            nil

          children ->
            Enum.map(children, fn {_, pid, _, _} ->
              Process.unlink(pid)
              Process.exit(pid, :shutdown)
            end)
        end
      end)

      {:ok, %{auction: auction, fuel: fuel, fuel_id: fuel_id, supplier_company: supplier_company}}
    end

    test "place_bid/2 enters bid in bid_list and runs lowest_bid logic", %{
      auction: auction,
      fuel_id: fuel_id,
      supplier_company: supplier_company
    } do
      amount = 1.25

      expected_result = %{
        amount: amount,
        auction_id: auction.id,
        fuel_id: fuel_id,
        supplier_id: supplier_company.id,
        time_entered: DateTime.utc_now()
      }

      assert bid =
               %AuctionBid{} =
               create_bid(amount, nil, supplier_company.id, fuel_id, auction)
               |> Auctions.place_bid()

      assert Enum.all?(expected_result, fn {k, v} ->
               if k == :time_entered do
                 Map.fetch!(bid, k) >= v
               else
                 Map.fetch!(bid, k) == v
               end
             end)

      auction_payload = Auctions.AuctionPayload.get_auction_payload!(auction, supplier_company.id)
      product_payload = auction_payload.product_bids["#{fuel_id}"]

      assert hd(product_payload.bid_history).id == bid.id
      assert hd(product_payload.lowest_bids).id == bid.id
    end

    test "revoke_supplier_bids_for_product/4 enters bid in bid_list and runs lowest_bid logic", %{
      auction: auction,
      fuel_id: fuel_id,
      supplier_company: supplier_company
    } do
      create_bid(1.50, nil, supplier_company.id, fuel_id, auction)
      |> Auctions.place_bid()
      :timer.sleep(100)

      Auctions.revoke_supplier_bids_for_product(auction, fuel_id, supplier_company.id)

      auction_payload = Auctions.AuctionPayload.get_auction_payload!(auction, supplier_company.id)
      product_payload = auction_payload.product_bids["#{fuel_id}"]

      # `bid_history` still contains the bid for auditing, but it is not in
      # `lowest_bids` because it is inactive.
      assert length(product_payload.bid_history) == 1
      assert length(product_payload.lowest_bids) == 0
    end

    test "revoke_supplier_bids_for_product/4 fails when auction is in decision", %{
      auction: auction,
      fuel_id: fuel_id,
      supplier_company: supplier_company
    } do
      create_bid(1.25, nil, supplier_company.id, fuel_id, auction)
      |> Auctions.place_bid()

      Auctions.end_auction(auction)
      :timer.sleep(50)

      result = Auctions.revoke_supplier_bids_for_product(auction, fuel_id, supplier_company.id)
      assert {:error, :late_bid} = result
    end
  end

  describe "ports" do
    alias Oceanconnect.Auctions.Port

    @valid_attrs_inactive %{name: "some other port", country: "Merica", is_active: false}
    @invalid_attrs %{name: nil, country: "Merica"}

    setup do
      valid_attrs = %{name: "some port", country: "Merica", is_active: true}
      update_attrs = %{name: "some updated port", country: "Merica"}
      port = insert(:port, valid_attrs)
      inactive_port = insert(:port, @valid_attrs_inactive)
      companies = insert_list(2, :company)

      {:ok,
       %{
         port: Auctions.get_port!(port.id),
         inactive_port: Auctions.get_port!(inactive_port.id),
         valid_attrs: valid_attrs,
         update_attrs: update_attrs,
         companies: companies
       }}
    end

    test "list_ports/0 returns all ports", %{port: port, inactive_port: inactive_port} do
      assert Enum.map(Auctions.list_ports(), fn f -> f.id end) == [port.id, inactive_port.id]
    end

    test "list_ports/1 returns a paginated list of all ports", %{
      port: port,
      inactive_port: inactive_port
    } do
      page = Auctions.list_ports(%{})
      assert page.entries == [inactive_port, port]
    end

    test "list_active_ports/0 returns all ports marked as active", %{
      port: port,
      inactive_port: inactive_port
    } do
      assert Enum.map(Auctions.list_active_ports(), fn f -> f.id end) == [port.id]

      refute Enum.map(Auctions.list_active_ports(), fn f -> f.id end) == [
               port.id,
               inactive_port.id
             ]
    end

    test "get_port!/1 returns the port with given id", %{port: port} do
      assert Auctions.get_port!(port.id) == port
    end

    test "get_active_port!/1 returns the active port with given id", %{
      port: port,
      inactive_port: inactive_port
    } do
      assert Auctions.get_active_port!(port.id) == port
      assert_raise Ecto.NoResultsError, fn -> Auctions.get_active_port!(inactive_port.id) end
    end

    test "create_port/1 with valid data creates a port", %{valid_attrs: valid_attrs} do
      assert {:ok, port} = Auctions.create_port(valid_attrs)
      assert all_values_match?(valid_attrs, port)
    end

    test "create_port/1 with valid data and companies creates a port", %{
      valid_attrs: valid_attrs,
      companies: companies
    } do
      company_ids =
        Enum.map(companies, fn company ->
          Integer.to_string(company.id)
        end)

      assert {:ok, port} =
               Auctions.create_port(%{
                 "name" => valid_attrs.name,
                 "country" => valid_attrs.country,
                 "companies" => company_ids
               })

      assert %Port{} = port
      port = Auctions.port_with_companies(port)
      assert all_values_match?(Map.put(valid_attrs, :companies, companies), port)
    end

    test "create_port/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Auctions.create_port(@invalid_attrs)
    end

    test "udpate_port/2 with valid data updates the port", %{
      port: port,
      update_attrs: update_attrs
    } do
      assert {:ok, port} = Auctions.update_port(port, update_attrs)
      assert %Port{} = port
      port = Auctions.port_with_companies(port)
      assert all_values_match?(update_attrs, port)
    end

    test "update_port/2 with valid data and companies updates the port", %{
      port: port,
      update_attrs: update_attrs,
      companies: companies
    } do
      company_ids =
        Enum.map(companies, fn company ->
          Integer.to_string(company.id)
        end)

      port = Auctions.port_with_companies(port)

      assert {:ok, port} =
               Auctions.update_port(port, %{
                 "name" => update_attrs.name,
                 "country" => update_attrs.country,
                 "companies" => company_ids,
                 "removed_companies" => []
               })

      assert %Port{} = port
      port = Auctions.port_with_companies(port)
      assert all_values_match?(Map.put(update_attrs, :companies, companies), port)
    end

    test "update_port/2 with invalid data returns error changeset", %{port: port} do
      assert {:error, %Ecto.Changeset{}} = Auctions.update_port(port, @invalid_attrs)
      assert port == Auctions.get_port!(port.id)
    end

    test "delete_port/1 deletes the port", %{port: port} do
      assert {:ok, %Port{}} = Auctions.delete_port(port)
      assert_raise Ecto.NoResultsError, fn -> Auctions.get_port!(port.id) end
    end

    test "activate_port/1 marks the port as active", %{inactive_port: inactive_port} do
      assert {:ok, %Port{is_active: true}} = Auctions.activate_port(inactive_port)
    end

    test "deactivate_port/1 marks the port as inactive", %{port: port} do
      assert {:ok, %Port{is_active: false}} = Auctions.deactivate_port(port)
    end

    test "change_port/1 returns a port changeset", %{port: port} do
      assert %Ecto.Changeset{} = Auctions.change_port(port)
    end

    test "port_with_companies/1 returns a port with companies", %{
      port: port,
      companies: companies
    } do
      company_ids = Enum.map(companies, fn company -> Integer.to_string(company.id) end)

      assert {:ok, port} =
               port
               |> Auctions.port_with_companies()
               |> Auctions.update_port(%{"companies" => company_ids, "removed_companies" => []})

      assert port.companies == companies
    end
  end

  describe "port and company relationship" do
    setup do
      [port1, port2, port3] = insert_list(3, :port)

      [company1, company2, company3, company5, company6] =
        insert_list(5, :company, is_supplier: true)

      company4 = insert(:company)
      company1 |> Oceanconnect.Accounts.add_port_to_company(port1)
      company2 |> Oceanconnect.Accounts.set_ports_on_company([port1, port2])
      company3 |> Oceanconnect.Accounts.add_port_to_company(port2)
      company4 |> Oceanconnect.Accounts.add_port_to_company(port1)

      {:ok,
       %{
         p1: port1,
         p2: port2,
         p3: port3,
         c1: company1,
         c2: company2,
         c3: company3,
         c5: company5,
         c6: company6
       }}
    end

    test "supplier_list_for_auction/1 returns only supplier companies for given port", %{
      p1: p1,
      p2: p2,
      c1: c1,
      c2: c2,
      c3: c3
    } do
      companies = Auctions.supplier_list_for_auction(p1)
      assert Enum.all?(companies, fn c -> c.id in [c1.id, c2.id] end)
      assert length(companies) == 2
      assert Enum.all?(Auctions.supplier_list_for_auction(p2), fn c -> c.id in [c2.id, c3.id] end)
    end

    test "supplier_list_for_auction/2 returns only supplier companies for given port and not buyer",
         %{p1: p1, c1: buyer, c2: c2} do
      companies = Auctions.supplier_list_for_auction(p1, buyer.id)
      assert length(companies) == 1
      assert hd(companies).id == c2.id
    end

    test "ports_for_company/1 returns ports for given company", %{p1: p1, p2: p2, c1: c1, c2: c2} do
      ports = Auctions.ports_for_company(c2)
      assert Enum.all?(ports, fn p -> p.id in [p1.id, p2.id] end)
      assert length(ports) == 2
      assert Enum.all?(Auctions.ports_for_company(c1), fn p -> p.id === p1.id end)
    end
  end

  describe "vessels" do
    alias Oceanconnect.Auctions.Vessel

    @valid_attrs %{imo: 42, name: "some name", is_active: true}
    @valid_attrs_ianctive %{imo: 41, name: "some other name", is_active: false}
    @update_attrs %{imo: 43, name: "some updated name"}
    @invalid_attrs %{imo: nil, name: nil}

    setup do
      company = insert(:company)
      company2 = insert(:company)
      vessel = insert(:vessel, Map.merge(@valid_attrs, %{company: company}))
      inactive_vessel = insert(:vessel, Map.merge(@valid_attrs_ianctive, %{company: company2}))
      user = insert(:user, company: company)

      {:ok,
       %{
         company: company,
         user: user,
         vessel: Auctions.get_vessel!(vessel.id),
         inactive_vessel: Auctions.get_vessel!(inactive_vessel.id)
       }}
    end

    test "vessels_for_buyer/1", %{user: user, vessel: vessel} do
      extra_vessel = insert(:vessel)

      result =
        Auctions.vessels_for_buyer(user.company)
        |> Oceanconnect.Repo.preload(:company)

      assert result == [vessel]
      refute extra_vessel in result
    end

    test "list_vessels/0 returns all vessels", %{vessel: vessel, inactive_vessel: inactive_vessel} do
      assert Enum.map(Auctions.list_vessels(), fn f -> f.id end) == [
               vessel.id,
               inactive_vessel.id
             ]
    end

    test "list_vessels/1 returns a paginated list of all vessels", %{
      vessel: vessel,
      inactive_vessel: inactive_vessel
    } do
      page = Auctions.list_vessels(%{})

      vessels =
        page.entries
        |> Repo.preload(:company)

      assert vessels == [vessel, inactive_vessel]
    end

    test "list_active_vessels/0 returns all vessels marked as active", %{
      vessel: vessel,
      inactive_vessel: inactive_vessel
    } do
      assert Enum.map(Auctions.list_active_vessels(), fn f -> f.id end) == [vessel.id]

      refute Enum.map(Auctions.list_active_vessels(), fn f -> f.id end) == [
               vessel.id,
               inactive_vessel.id
             ]
    end

    test "get_vessel!/1 returns the vessel with given id", %{vessel: vessel} do
      assert Auctions.get_vessel!(vessel.id) == vessel
    end

    test "get_active_vessel!/1 returns the active vessel with given id", %{
      vessel: vessel,
      inactive_vessel: inactive_vessel
    } do
      assert Auctions.get_active_vessel!(vessel.id) |> Repo.preload(:company) == vessel
      assert_raise Ecto.NoResultsError, fn -> Auctions.get_active_vessel!(inactive_vessel.id) end
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

    test "update_vessel/2 with invalid data returns error changeset", %{vessel: vessel} do
      assert {:error, %Ecto.Changeset{}} = Auctions.update_vessel(vessel, @invalid_attrs)
      assert vessel == Auctions.get_vessel!(vessel.id)
    end

    test "delete_vessel/1 deletes the vessel", %{vessel: vessel} do
      assert {:ok, %Vessel{}} = Auctions.delete_vessel(vessel)
      assert_raise Ecto.NoResultsError, fn -> Auctions.get_vessel!(vessel.id) end
    end

    test "activate_vessel/1 marks the vessel as active", %{inactive_vessel: inactive_vessel} do
      assert {:ok, %Vessel{is_active: true}} = Auctions.activate_vessel(inactive_vessel)
    end

    test "deactivate_vessel/1 marks the vessel as inactive", %{vessel: vessel} do
      assert {:ok, %Vessel{is_active: false}} = Auctions.deactivate_vessel(vessel)
    end

    test "change_vessel/1 returns a vessel changeset", %{vessel: vessel} do
      assert %Ecto.Changeset{} = Auctions.change_vessel(vessel)
    end
  end

  describe "fuels" do
    alias Oceanconnect.Auctions.Fuel

    @valid_attrs %{name: "some name", is_active: true}
    @valid_attrs_inactive %{name: "some other name", is_active: false}
    @update_attrs %{name: "some updated name"}
    @invalid_attrs %{name: nil}

    setup do
      fuel = insert(:fuel, @valid_attrs)
      inactive_fuel = insert(:fuel, @valid_attrs_inactive)

      {:ok,
       %{fuel: Auctions.get_fuel!(fuel.id), inactive_fuel: Auctions.get_fuel!(inactive_fuel.id)}}
    end

    test "list_fuels/0 returns all fuels", %{fuel: fuel, inactive_fuel: inactive_fuel} do
      assert Enum.map(Auctions.list_fuels(), fn f -> f.id end) == [fuel.id, inactive_fuel.id]
    end

    test "list_fuels/1 returns a paginated list of all fuels", %{
      fuel: fuel,
      inactive_fuel: inactive_fuel
    } do
      page = Auctions.list_fuels(%{})
      assert page.entries == [fuel, inactive_fuel]
    end

    test "list_active_fuels/0 returns all fuels marked as active", %{
      fuel: fuel,
      inactive_fuel: inactive_fuel
    } do
      assert Enum.map(Auctions.list_active_fuels(), fn f -> f.id end) == [fuel.id]

      refute Enum.map(Auctions.list_active_fuels(), fn f -> f.id end) == [
               fuel.id,
               inactive_fuel.id
             ]
    end

    test "get_fuel!/1 returns the fuel with given id", %{fuel: fuel} do
      assert Auctions.get_fuel!(fuel.id) == fuel
    end

    test "get_active_fuel!/1 returns the active fuel with given id", %{
      fuel: fuel,
      inactive_fuel: inactive_fuel
    } do
      assert Auctions.get_active_fuel!(fuel.id) == fuel
      assert_raise Ecto.NoResultsError, fn -> Auctions.get_active_fuel!(inactive_fuel.id) end
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

    test "activate_fuel/1 marks the fuel as active", %{inactive_fuel: inactive_fuel} do
      assert {:ok, %Fuel{is_active: true}} = Auctions.activate_fuel(inactive_fuel)
    end

    test "deactivate_fuel/1 marks the fuel as inactive", %{fuel: fuel} do
      assert {:ok, %Fuel{is_active: false}} = Auctions.deactivate_fuel(fuel)
    end

    test "change_fuel/1 returns a fuel changeset", %{fuel: fuel} do
      assert %Ecto.Changeset{} = Auctions.change_fuel(fuel)
    end
  end

  describe "auction barges" do
    setup do
      supplier_company = insert(:company, is_supplier: true)
      supplier_company2 = insert(:company, is_supplier: true)
      buyer_company = insert(:company, is_supplier: false)

      auction =
        insert(:auction, suppliers: [supplier_company, supplier_company2], buyer: buyer_company)
        |> Auctions.fully_loaded()

      {:ok, _pid} =
        start_supervised(
          {AuctionSupervisor,
           {auction, %{exclude_children: [:auction_reminder_timer, :auction_scheduler]}}}
        )

      {:ok, %{auction: auction, supplier: supplier_company, supplier2: supplier_company2}}
    end

    test "list_auction_barges/1 lists all barges submitted to an auction", %{
      auction: auction,
      supplier: supplier,
      supplier2: supplier2
    } do
      barge1 = insert(:barge, companies: [supplier])
      barge2 = insert(:barge, companies: [supplier2])

      insert(:auction_barge, auction: auction, barge: barge1, supplier: supplier)
      insert(:auction_barge, auction: auction, barge: barge2, supplier: supplier2)

      [first, second] = Auctions.list_auction_barges(auction)
      assert first.barge_id == barge1.id
      assert second.barge_id == barge2.id
    end

    test "list_auction_barges/1 allows the same barge to be submitted by multiple suppliers", %{
      auction: auction,
      supplier: supplier,
      supplier2: supplier2
    } do
      barge = insert(:barge, companies: [supplier, supplier2])
      barge_id = barge.id
      supplier_id = supplier.id
      supplier2_id = supplier2.id

      insert(:auction_barge, auction: auction, barge: barge, supplier: supplier)
      insert(:auction_barge, auction: auction, barge: barge, supplier: supplier2)

      [first, second] = Auctions.list_auction_barges(auction)
      assert %Auctions.AuctionBarge{barge_id: ^barge_id, supplier_id: ^supplier_id} = first
      assert %Auctions.AuctionBarge{barge_id: ^barge_id, supplier_id: ^supplier2_id} = second
    end

    test "submit_barge/3 adds given barge to auction for the supplier", %{
      auction: auction,
      supplier: supplier
    } do
      barge = insert(:barge, companies: [supplier])
      barge_id = barge.id
      supplier_id = supplier.id

      Auctions.submit_barge(auction, barge, supplier.id)
      auction_state = Auctions.get_auction_state!(auction)

      assert length(auction_state.submitted_barges) == 1

      assert %Auctions.AuctionBarge{
               barge_id: ^barge_id,
               supplier_id: ^supplier_id,
               approval_status: "PENDING"
             } = hd(auction_state.submitted_barges)
    end

    test "submit_barge/3 allows multiple suppliers to submit the same barge", %{
      auction: auction,
      supplier: supplier,
      supplier2: supplier2
    } do
      barge = insert(:barge, companies: [supplier, supplier2])
      barge_id = barge.id
      supplier_id = supplier.id
      supplier2_id = supplier2.id

      Auctions.submit_barge(auction, barge, supplier.id)
      Auctions.submit_barge(auction, barge, supplier2.id)
      auction_state = Auctions.get_auction_state!(auction)

      [first, second] = auction_state.submitted_barges

      assert %Auctions.AuctionBarge{
               barge_id: ^barge_id,
               supplier_id: ^supplier_id,
               approval_status: "PENDING"
             } = first

      assert %Auctions.AuctionBarge{
               barge_id: ^barge_id,
               supplier_id: ^supplier2_id,
               approval_status: "PENDING"
             } = second
    end

    test "unsubmit_barge/3 removes given barge to auction for the supplier", %{
      auction: auction,
      supplier: supplier
    } do
      barge = insert(:barge, companies: [supplier])

      Auctions.submit_barge(auction, barge, supplier.id)
      Auctions.unsubmit_barge(auction, barge, supplier.id)
      auction_state = Auctions.get_auction_state!(auction)
      assert length(auction_state.submitted_barges) == 0
    end

    test "unsubmit_barge/3 preserves barge submissions from other suppliers", %{
      auction: auction,
      supplier: supplier,
      supplier2: supplier2
    } do
      barge = insert(:barge, companies: [supplier, supplier2])
      barge_id = barge.id
      supplier2_id = supplier2.id

      Auctions.submit_barge(auction, barge, supplier.id)
      Auctions.submit_barge(auction, barge, supplier2.id)
      Auctions.unsubmit_barge(auction, barge, supplier.id)
      auction_state = Auctions.get_auction_state!(auction)

      [second] = auction_state.submitted_barges

      assert %Auctions.AuctionBarge{
               barge_id: ^barge_id,
               supplier_id: ^supplier2_id,
               approval_status: "PENDING"
             } = second
    end

    test "approve_barge/3 updates the approval status of a submitted barge for a supplier", %{
      auction: auction,
      supplier: supplier
    } do
      barge = insert(:barge, companies: [supplier])

      barge_id = barge.id
      supplier_id = supplier.id

      Auctions.submit_barge(auction, barge, supplier.id)
      Auctions.approve_barge(auction, barge, supplier.id)
      auction_state = Auctions.get_auction_state!(auction)

      [submitted_barge] = auction_state.submitted_barges

      assert %Auctions.AuctionBarge{
               barge_id: ^barge_id,
               supplier_id: ^supplier_id,
               approval_status: "APPROVED"
             } = submitted_barge
    end

    test "approve_barge/3 does not update approval status of barge submitted by other suppliers",
         %{auction: auction, supplier: supplier, supplier2: supplier2} do
      barge = insert(:barge, companies: [supplier, supplier2])

      barge_id = barge.id
      supplier_id = supplier.id
      supplier2_id = supplier2.id

      Auctions.submit_barge(auction, barge, supplier.id)
      Auctions.submit_barge(auction, barge, supplier2.id)
      Auctions.approve_barge(auction, barge, supplier.id)
      auction_state = Auctions.get_auction_state!(auction)

      assert [
               %Auctions.AuctionBarge{
                 barge_id: ^barge_id,
                 supplier_id: ^supplier_id,
                 approval_status: "APPROVED"
               },
               %Auctions.AuctionBarge{
                 barge_id: ^barge_id,
                 supplier_id: ^supplier2_id,
                 approval_status: "PENDING"
               }
             ] = auction_state.submitted_barges
    end

    test "reject_barge/3 updates the approval status of a submitted barge", %{
      auction: auction,
      supplier: supplier
    } do
      barge = insert(:barge, companies: [supplier])

      barge_id = barge.id
      supplier_id = supplier.id

      Auctions.submit_barge(auction, barge, supplier.id)
      Auctions.reject_barge(auction, barge, supplier.id)
      auction_state = Auctions.get_auction_state!(auction)

      [submitted_barge] = auction_state.submitted_barges

      assert %Auctions.AuctionBarge{
               barge_id: ^barge_id,
               supplier_id: ^supplier_id,
               approval_status: "REJECTED"
             } = submitted_barge
    end

    test "reject_barge/3 does not update approval status of barge submitted by other suppliers",
         %{auction: auction, supplier: supplier, supplier2: supplier2} do
      barge = insert(:barge, companies: [supplier, supplier2])

      barge_id = barge.id
      supplier_id = supplier.id
      supplier2_id = supplier2.id

      Auctions.submit_barge(auction, barge, supplier.id)
      Auctions.submit_barge(auction, barge, supplier2.id)
      Auctions.approve_barge(auction, barge, supplier.id)
      auction_state = Auctions.get_auction_state!(auction)

      assert [
               %Auctions.AuctionBarge{
                 barge_id: ^barge_id,
                 supplier_id: ^supplier_id,
                 approval_status: "APPROVED"
               },
               %Auctions.AuctionBarge{
                 barge_id: ^barge_id,
                 supplier_id: ^supplier2_id,
                 approval_status: "PENDING"
               }
             ] = auction_state.submitted_barges
    end
  end

  describe "barges" do
    alias Oceanconnect.Auctions.Barge

    @valid_attrs %{
      name: "some name",
      imo_number: "1337",
      dwt: "37",
      sire_inspection_date: DateTime.utc_now(),
      sire_inspection_validity: true,
      is_active: true
    }
    @valid_attrs_inactive %{
      name: "some other name",
      imo_number: "1336",
      dwt: "36",
      sire_inspection_date: DateTime.utc_now(),
      sire_inspection_validity: true,
      is_active: false
    }
    @update_attrs %{
      name: "some updated name",
      imo_number: "1338",
      dwt: "38",
      sire_inspection_date: DateTime.utc_now(),
      sire_inspection_validity: true
    }
    @invalid_attrs %{
      name: nil,
      imo_number: nil,
      dwt: nil,
      sire_inspection_date: DateTime.utc_now(),
      sire_inspection_validity: true
    }

    setup do
      port = insert(:port)
      barge = insert(:barge, Map.merge(@valid_attrs, %{port: port}))
      inactive_barge = insert(:barge, Map.merge(@valid_attrs_inactive, %{port: port}))
      barge_with_no_supplier = insert(:barge, %{companies: []})
      companies = insert_list(2, :company)

      {:ok,
       %{
         barge: Auctions.get_barge!(barge.id),
         inactive_barge: Auctions.get_barge!(inactive_barge.id),
         port: Auctions.get_port!(port.id),
         barge_with_no_supplier: barge_with_no_supplier,
         companies: companies
       }}
    end

    test "list_barges/0 returns all barges", %{
      barge: barge,
      inactive_barge: inactive_barge,
      barge_with_no_supplier: barge2
    } do
      assert Enum.map(Auctions.list_barges(), fn b -> b.id end) == [
               barge.id,
               inactive_barge.id,
               barge2.id
             ]
    end

    test "list_barges/1 returns a paginated list of all barges", %{
      barge: barge,
      inactive_barge: inactive_barge,
      barge_with_no_supplier: barge2
    } do
      page = Auctions.list_barges(%{})
      assert Enum.map(page.entries, fn b -> b.id end) == [barge2.id, barge.id, inactive_barge.id]
    end

    test "list_active_barges/0 returns all barges marked as active", %{
      barge: barge,
      inactive_barge: inactive_barge,
      barge_with_no_supplier: barge2
    } do
      assert Enum.map(Auctions.list_active_barges(), fn b -> b.id end) == [barge.id, barge2.id]

      refute Enum.map(Auctions.list_active_barges(), fn b -> b.id end) == [
               barge.id,
               inactive_barge.id
             ]
    end

    test "get_barge!/1 returns the barge with given id", %{barge: barge} do
      assert Auctions.get_barge!(barge.id) == barge
    end

    test "get_active_barge!/1 returns the active barge with given id", %{
      barge: barge,
      inactive_barge: inactive_barge
    } do
      assert Auctions.get_active_barge!(barge.id) == barge
      assert_raise Ecto.NoResultsError, fn -> Auctions.get_active_barge!(inactive_barge.id) end
    end

    test "strip non loaded" do
      auction = insert(:auction)

      partially_loaded_auction =
        Oceanconnect.Auctions.Auction
        |> Repo.get(auction.id)
        |> Repo.preload([:vessels])

      result = Auctions.strip_non_loaded(partially_loaded_auction)
      assert hd(result.vessels).company == nil
    end

    test "create_barge/1 with valid data creates a barge", %{port: port} do
      attrs = Map.merge(@valid_attrs, %{port_id: port.id})
      assert {:ok, %Barge{} = barge} = Auctions.create_barge(attrs)
      assert barge.name == "some name"
    end

    test "create_barge/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Auctions.create_barge(@invalid_attrs)
    end

    test "update_barge/2 with valid data updates the barge", %{barge: barge} do
      assert {:ok, barge} = Auctions.update_barge(barge, @update_attrs)
      assert %Barge{} = barge
      assert barge.name == "some updated name"
    end

    test "update_barge/2 with invalid data returns error changeset", %{barge: barge} do
      assert {:error, %Ecto.Changeset{}} = Auctions.update_barge(barge, @invalid_attrs)
      assert barge == Auctions.get_barge!(barge.id)
    end

    test "delete_barge/1 deletes the barge", %{barge: barge} do
      assert {:ok, %Barge{}} = Auctions.delete_barge(barge)
      assert_raise Ecto.NoResultsError, fn -> Auctions.get_barge!(barge.id) end
    end

    test "activate_barge/1 marks the barge as active", %{inactive_barge: inactive_barge} do
      assert {:ok, %Barge{is_active: true}} = Auctions.activate_barge(inactive_barge)
    end

    test "deactivate_barge/1 marks the barge as inactive", %{barge: barge} do
      assert {:ok, %Barge{is_active: false}} = Auctions.deactivate_barge(barge)
    end

    test "change_barge/1 returns a barge changeset", %{barge: barge} do
      assert %Ecto.Changeset{} = Auctions.change_barge(barge)
    end

    test "barge_with_companies/1 returns a barge with companies", %{
      barge_with_no_supplier: barge,
      companies: companies
    } do
      company_ids = Enum.map(companies, fn company -> Integer.to_string(company.id) end)

      assert {:ok, barge} =
               barge
               |> Auctions.barge_with_companies()
               |> Auctions.update_barge(%{"companies" => company_ids, "removed_companies" => []})

      assert barge.companies == companies
    end
  end
end
