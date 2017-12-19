defmodule OceanconnectWeb.AuctionControllerTest do
  use OceanconnectWeb.ConnCase

  alias Oceanconnect.Auctions

  @port_attrs %{ name: "some port", country: "Merica" }
  @create_attrs %{ vessel: "some vessel" }
  @update_attrs %{ vessel: "some updated vessel"}
  @invalid_attrs %{ vessel: nil}


  def valid_auction_create_attrs(attrs \\ %{}) do
    {:ok, port} = Auctions.create_port(%{name: "some port", country: "Merica"})
    %{port_id: port.id}
      |> Map.merge( attrs)
      |> Enum.into(@create_attrs)

  end


  def fixture(:auction) do
    {:ok, port} = Auctions.create_port(@port_attrs)
    auction_with_port = Map.put(@create_attrs, :port_id, port.id)

    {:ok, auction} = Auctions.create_auction(auction_with_port)
    auction
  end

  describe "index" do
    test "lists all auctions", %{conn: conn} do
      conn = get conn, auction_path(conn, :index)
      assert html_response(conn, 200) =~ "Auction Listing"
    end
  end

  describe "new auction" do
    test "renders form", %{conn: conn} do
      conn = get conn, auction_path(conn, :new)
      assert html_response(conn, 200) =~ "New Auction"
    end
  end

  describe "create auction" do
    setup do
      port = insert(:port)
      invalid_attrs = Map.merge(@invalid_attrs, %{port_id: port.id})
      {:ok, %{invalid_attrs: invalid_attrs}}
    end
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post conn, auction_path(conn, :create), auction: valid_auction_create_attrs()

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == auction_path(conn, :show, id)

      conn = get conn, auction_path(conn, :show, id)
      assert html_response(conn, 200) =~ "Show Auction"
    end

    test "renders errors when data is invalid", %{conn: conn, invalid_attrs: invalid_attrs} do
      conn = post conn, auction_path(conn, :create), auction: invalid_attrs

      assert conn.assigns[:auction] == struct(Auctions.Auction, invalid_attrs) |> Auctions.with_port
      assert html_response(conn, 200) =~ "New Auction"
    end
  end

  describe "edit auction" do
    setup [:create_auction]

    test "renders form for editing chosen auction", %{conn: conn, auction: auction} do
      conn = get conn, auction_path(conn, :edit, auction)
      assert html_response(conn, 200) =~ "Edit Auction"
    end
  end

  describe "update auction" do
    setup [:create_auction]

    test "redirects when data is valid", %{conn: conn, auction: auction} do
      conn = put conn, auction_path(conn, :update, auction), auction: @update_attrs
      assert redirected_to(conn) == auction_path(conn, :show, auction)

      conn = get conn, auction_path(conn, :show, auction)
      assert html_response(conn, 200) =~ "some updated vessel"
    end

    test "renders errors when data is invalid", %{conn: conn, auction: auction} do
      conn = put conn, auction_path(conn, :update, auction), auction: @invalid_attrs
      assert html_response(conn, 200) =~ "Edit Auction"
    end
  end

  describe "delete auction" do
    setup [:create_auction]

    test "deletes chosen auction", %{conn: conn, auction: auction} do
      conn = delete conn, auction_path(conn, :delete, auction)
      assert redirected_to(conn) == auction_path(conn, :index)
      assert_error_sent 404, fn ->
        get conn, auction_path(conn, :show, auction)
      end
    end
  end

  defp create_auction(_) do
    auction = fixture(:auction)
    {:ok, auction: auction}
  end

end
