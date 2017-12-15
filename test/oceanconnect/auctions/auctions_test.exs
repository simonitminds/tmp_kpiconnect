defmodule Oceanconnect.AuctionsTest do
  use Oceanconnect.DataCase

  alias Oceanconnect.Auctions

  describe "auctions" do
    alias Oceanconnect.Auctions.Auction

    @valid_attrs %{port: "some port", vessel: "some vessel"}
    @update_attrs %{port: "some updated port", vessel: "some updated vessel"}
    @invalid_attrs %{port: nil, vessel: nil}

    def auction_fixture(attrs \\ %{}) do
      {:ok, auction} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Auctions.create_auction()

      auction
    end

    test "#start_date_from_params" do
      params = %{"anonymous_bidding" => "false",
      "auction_start" => %{"date" => "2017-12-28", "hour" => "01",
      "minute" => "30"}, "company" => "", "duration" => "",
      "eta" => %{"date" => "", "hour" => "00", "minute" => "00"},
      "etd" => %{"date" => "", "hour" => "00", "minute" => "00"}, "po" => "",
      "port" => "", "vessel" => ""}
      parsed_date = Auction.start_date_from_params(params)
      {:ok, expected_date} = NaiveDateTime.new(2017, 12, 28, 1, 30, 0)

      assert parsed_date == expected_date
    end

    # test "persisting a Auction with start_date set from params" do
    #   params = %{"anonymous_bidding" => "false",
    #   "auction_start" => %{"date" => "2017-12-28", "hour" => "01",
    #   "minute" => "30"}, "company" => "", "duration" => "",
    #   "eta" => %{"date" => "", "hour" => "00", "minute" => "00"},
    #   "etd" => %{"date" => "", "hour" => "00", "minute" => "00"}, "po" => "",
    #   "port" => "", "vessel" => ""}
    #   parsed_date = Auction.start_date_from_params(params)
    #
    #   result = %Auction{auction_start: parsed_date}
    #   |> Oceanconnect.Repo.insert()
    #   assert {:ok, %Auction{}} = result
    # end

    test "list_auctions/0 returns all auctions" do
      auction = auction_fixture()
      assert Auctions.list_auctions() == [auction]
    end

    test "get_auction!/1 returns the auction with given id" do
      auction = auction_fixture()
      assert Auctions.get_auction!(auction.id) == auction
    end

    test "create_auction/1 with valid data creates a auction" do
      assert {:ok, %Auction{} = auction} = Auctions.create_auction(@valid_attrs)
      assert auction.port == "some port"
      assert auction.vessel == "some vessel"
    end

    test "create_auction/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Auctions.create_auction(@invalid_attrs)
    end

    test "update_auction/2 with valid data updates the auction" do
      auction = auction_fixture()
      assert {:ok, auction} = Auctions.update_auction(auction, @update_attrs)
      assert %Auction{} = auction
      assert auction.port == "some updated port"
      assert auction.vessel == "some updated vessel"
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

    @valid_attrs %{name: "some name"}
    @update_attrs %{name: "some updated name"}
    @invalid_attrs %{name: nil}

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
      assert port.name == "some name"
    end

    test "create_port/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Auctions.create_port(@invalid_attrs)
    end

    test "update_port/2 with valid data updates the port" do
      port = port_fixture()
      assert {:ok, port} = Auctions.update_port(port, @update_attrs)
      assert %Port{} = port
      assert port.name == "some updated name"
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
end
