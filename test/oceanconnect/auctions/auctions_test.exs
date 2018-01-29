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
      params = %{"anonymous_bidding" => "false",
      "auction_start" => epoch, "company" => "", "duration" => "",
      "eta" => "", "etd" => "", "po" => "", "port" => "", "vessel" => ""}
      %{ "auction_start" => parsed_date } = Auction.maybe_parse_date_field(params, "auction_start")

      assert parsed_date == expected_date |> DateTime.to_string()
    end

    test "list_auctions/0 returns all auctions", %{auction: auction} do
      assert Auctions.list_auctions()
      |> Enum.map(fn(a) -> a.id end)
      |> MapSet.new
      |> MapSet.equal?(MapSet.new([auction.id]))
    end

    test "get_auction!/1 returns the auction with given id", %{auction: auction} do
      assert Auctions.get_auction!(auction.id) == auction
    end

    test "create_auction/1 with valid data creates a auction", %{auction: auction} do
      auction_attrs = auction |> Map.take([:fuel_id, :port_id, :vessel_id] ++ Map.keys(@valid_attrs))
      assert {:ok, %Auction{} = new_auction} = Auctions.create_auction(auction_attrs)
      assert all_values_match?(auction_attrs, new_auction)
    end

    test "create_auction/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Auctions.create_auction(@invalid_attrs)
    end

    test "update_auction/2 with valid data updates the auction", %{auction: auction} do
      assert {:ok, auction} = Auctions.update_auction(auction, @update_attrs)
      assert %Auction{} = auction
      assert auction.po == "some updated po"
    end

    test "update_auction/2 with invalid data returns error changeset", %{auction: auction} do
      assert {:error, %Ecto.Changeset{}} = Auctions.update_auction(auction, @invalid_attrs)
      assert auction == Auctions.get_auction!(auction.id)
    end

    test "delete_auction/1 deletes the auction", %{auction: auction} do
      assert {:ok, %Auction{}} = Auctions.delete_auction(auction)
      assert_raise Ecto.NoResultsError, fn -> Auctions.get_auction!(auction.id) end
    end

    test "change_auction/1 returns a auction changeset", %{auction: auction} do
      assert %Ecto.Changeset{} = Auctions.change_auction(auction)
    end

    test "add_supplier_to_auction/2 with valid data", %{auction: auction} do
      supplier = insert(:user)
      updated_auction = auction |> Auctions.add_supplier_to_auction(supplier)
      assert updated_auction.suppliers == [supplier]
    end

    test "add_supplier_to_auction/2 with existing suppliers", %{auction: auction} do
      [s1, s2] = insert_list(2, :user)
      updated_auction = auction |> Auctions.add_supplier_to_auction(s1)
      |> Auctions.add_supplier_to_auction(s2)
      assert updated_auction.suppliers
      |> Enum.map(fn(s) -> s.id end)
      |> MapSet.new
      |> MapSet.equal?(MapSet.new([s1.id, s2.id]))
    end

    test "set_suppliers_for_auction/2 with valid data", %{auction: auction} do
      [s1, s2] = insert_list(2, :user)
      updated_auction = auction |> Auctions.set_suppliers_for_auction([s1, s2])
      assert updated_auction.suppliers
      |> Enum.map(fn(s) -> s.id end)
      |> MapSet.new
      |> MapSet.equal?(MapSet.new([s1.id, s2.id]))
    end

    test "set_suppliers_for_auction/2 overwriting existing suppliers", %{auction: auction} do
      [s1, s2, s3] = insert_list(3, :user)
      updated_auction = auction |> Auctions.add_supplier_to_auction(s3)
      |> Auctions.set_suppliers_for_auction([s1, s2])
      assert updated_auction.suppliers
      |> Enum.map(fn(s) -> s.id end)
      |> MapSet.new
      |> MapSet.equal?(MapSet.new([s1.id, s2.id]))
    end

    test "auction status" do
      auction_attrs = insert(:auction)|> Map.take([:buyer_id, :fuel_id, :port_id, :vessel_id] ++ Map.keys(@valid_attrs))
      {:ok, auction} = Auctions.create_auction(auction_attrs)

      assert :pending = Auctions.auction_state(auction).state.status
      Auctions.start_auction(auction)
      assert :open = Auctions.auction_state(auction).state.status
      Auctions.start_auction(auction)
      assert :open = Auctions.auction_state(auction).state.status
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

  describe "companies by port" do
    setup do
      [port1, port2] = insert_list(2, :port)
      [company1, company2, company3] = insert_list(3, :company)
      company1 |> Oceanconnect.Accounts.add_port_to_company(port1)
      company2 |> Oceanconnect.Accounts.set_ports_on_company([port1, port2])
      company3 |> Oceanconnect.Accounts.add_port_to_company(port2)
      {:ok, %{p1: port1, p2: port2, c1: company1, c2: company2, c3: company3}}
    end
    test "companies_by_port/1 returns companies with associated port", %{p1: p1, p2: p2, c1: c1, c2: c2, c3: c3} do
      companies = Auctions.companies_by_port(p1.id)
      assert Enum.all?(companies, fn(c) -> c.id in [c1.id, c2.id] end)
      assert length(companies) == 2
      assert Enum.all?(Auctions.companies_by_port(p2.id), fn(c) -> c.id in [c2.id, c3.id] end)
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
      result = Auctions.vessels_for_buyer(user)
      |> Oceanconnect.Repo.preload(:company)
      assert result == [vessel]
      refute extra_vessel in result
    end

    test "list_vessels/0 returns all vessels", %{vessel: vessel} do
      assert Auctions.list_vessels() == [vessel]
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
      assert Auctions.list_fuels() == [fuel]
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
end
