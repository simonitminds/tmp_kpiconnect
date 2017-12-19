defmodule Oceanconnect.AuctionsTest do
  use Oceanconnect.DataCase

  alias Oceanconnect.Auctions

  describe "auctions" do
    alias Oceanconnect.Auctions.Auction

    @valid_attrs %{ po: "some po"}
    @update_attrs %{ po: "some updated po"}
    @invalid_attrs %{ vessel_id: nil}

    def auction_fixture(attrs \\ %{}) do
      {:ok, auction} = valid_auction_attr(attrs)
        |> Auctions.create_auction()

      auction
    end

    def auction_with_port_fixture(attrs \\ %{}) do
      auction_fixture(attrs)
        |> Auctions.fully_loaded
    end

    def valid_auction_attr(attrs \\ %{}) do
      port = port_fixture()
      vessel = vessel_fixture()
      %{port_id: port.id, vessel_id: vessel.id}
        |> Map.merge( attrs)
        |> Enum.into(@valid_attrs)
    end

    test "#maybe_parse_date_field" do
      params = %{"anonymous_bidding" => "false",
      "auction_start" => %{"date" => "28/12/2017", "hour" => "1",
      "minute" => "30"}, "company" => "", "duration" => "",
      "eta" => %{"date" => "", "hour" => "0", "minute" => "0"},
      "etd" => %{"date" => "", "hour" => "0", "minute" => "0"}, "po" => "",
      "port" => "", "vessel" => ""}
      %{ "auction_start" => parsed_date } = Auction.maybe_parse_date_field(params, "auction_start")
      {:ok, expected_date} = NaiveDateTime.new(2017, 12, 28, 1, 30, 0)
      expected_date = expected_date |> NaiveDateTime.to_string()

      assert parsed_date == expected_date
    end

    test "list_auctions/0 returns all auctions" do
      auction = auction_with_port_fixture()
      assert Auctions.list_auctions() == [auction]
    end

    test "get_auction!/1 returns the auction with given id" do
      auction = auction_fixture()
      assert Auctions.get_auction!(auction.id) == auction
    end

    test "create_auction/1 with valid data creates a auction" do
      assert {:ok, %Auction{} = auction} = Auctions.create_auction(valid_auction_attr())
      assert auction.po == "some po"
    end

    test "create_auction/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Auctions.create_auction(@invalid_attrs)
    end

    test "update_auction/2 with valid data updates the auction" do
      auction = auction_fixture()
      assert {:ok, auction} = Auctions.update_auction(auction, @update_attrs)
      assert %Auction{} = auction
      assert auction.po == "some updated po"
    end

    test "update_auction/2 with invalid data returns error changeset" do
      auction = auction_fixture()
      assert {:error, %Ecto.Changeset{}} = Auctions.update_auction(auction, @invalid_attrs)
      assert auction == Auctions.get_auction!(auction.id)
    end

    test "delete_auction/1 deletes the auction" do
      auction = auction_fixture()
      assert {:ok, %Auction{}} = Auctions.delete_auction(auction)
      assert_raise Ecto.NoResultsError, fn -> Auctions.get_auction!(auction.id) end
    end

    test "change_auction/1 returns a auction changeset" do
      auction = auction_fixture()
      assert %Ecto.Changeset{} = Auctions.change_auction(auction)
    end
  end

  describe "ports" do
    alias Oceanconnect.Auctions.Port

    @valid_attrs %{name: "some port", country: "Merica"}
    @update_attrs %{name: "some updated port", country: "Merica"}
    @invalid_attrs %{name: nil, country: "Merica"}

    def port_fixture(attrs \\ %{}) do
      {:ok, port} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Auctions.create_port()

      port
    end

    test "list_ports/0 returns all ports" do
      port = port_fixture()
      assert Auctions.list_ports() == [port]
    end

    test "get_port!/1 returns the port with given id" do
      port = port_fixture()
      assert Auctions.get_port!(port.id) == port
    end

    test "create_port/1 with valid data creates a port" do
      assert {:ok, %Port{} = port} = Auctions.create_port(@valid_attrs)
      assert port.name == "some port"
    end

    test "create_port/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Auctions.create_port(@invalid_attrs)
    end

    test "update_port/2 with valid data updates the port" do
      port = port_fixture()
      assert {:ok, port} = Auctions.update_port(port, @update_attrs)
      assert %Port{} = port
      assert port.name == "some updated port"
    end

    test "update_port/2 with invalid data returns error changeset" do
      port = port_fixture()
      assert {:error, %Ecto.Changeset{}} = Auctions.update_port(port, @invalid_attrs)
      assert port == Auctions.get_port!(port.id)
    end

    test "delete_port/1 deletes the port" do
      port = port_fixture()
      assert {:ok, %Port{}} = Auctions.delete_port(port)
      assert_raise Ecto.NoResultsError, fn -> Auctions.get_port!(port.id) end
    end

    test "change_port/1 returns a port changeset" do
      port = port_fixture()
      assert %Ecto.Changeset{} = Auctions.change_port(port)
    end
  end

  describe "vessels" do
    alias Oceanconnect.Auctions.Vessel

    @valid_attrs %{imo: 42, name: "some name"}
    @update_attrs %{imo: 43, name: "some updated name"}
    @invalid_attrs %{imo: nil, name: nil}

    def vessel_fixture(attrs \\ %{}) do
      {:ok, vessel} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Auctions.create_vessel()

      vessel
    end

    test "list_vessels/0 returns all vessels" do
      vessel = vessel_fixture()
      assert Auctions.list_vessels() == [vessel]
    end

    test "get_vessel!/1 returns the vessel with given id" do
      vessel = vessel_fixture()
      assert Auctions.get_vessel!(vessel.id) == vessel
    end

    test "create_vessel/1 with valid data creates a vessel" do
      assert {:ok, %Vessel{} = vessel} = Auctions.create_vessel(@valid_attrs)
      assert vessel.imo == 42
      assert vessel.name == "some name"
    end

    test "create_vessel/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Auctions.create_vessel(@invalid_attrs)
    end

    test "update_vessel/2 with valid data updates the vessel" do
      vessel = vessel_fixture()
      assert {:ok, vessel} = Auctions.update_vessel(vessel, @update_attrs)
      assert %Vessel{} = vessel
      assert vessel.imo == 43
      assert vessel.name == "some updated name"
    end

    test "update_vessel/2 with invalid data returns error changeset" do
      vessel = vessel_fixture()
      assert {:error, %Ecto.Changeset{}} = Auctions.update_vessel(vessel, @invalid_attrs)
      assert vessel == Auctions.get_vessel!(vessel.id)
    end

    test "delete_vessel/1 deletes the vessel" do
      vessel = vessel_fixture()
      assert {:ok, %Vessel{}} = Auctions.delete_vessel(vessel)
      assert_raise Ecto.NoResultsError, fn -> Auctions.get_vessel!(vessel.id) end
    end

    test "change_vessel/1 returns a vessel changeset" do
      vessel = vessel_fixture()
      assert %Ecto.Changeset{} = Auctions.change_vessel(vessel)
    end
  end
end
