defmodule OceanconnectWeb.AuctionControllerTest do
  use OceanconnectWeb.ConnCase

  alias Oceanconnect.Auctions

  @update_attrs %{ po: "updated PO text"}
  @invalid_attrs %{ vessel_id: nil}

  setup do
    company = insert(:company)
    user = insert(:user, company: company)
    vessel = insert(:vessel, company: company) |> Oceanconnect.Repo.preload(:company)
    fuel = insert(:fuel)
    port = insert(:port)
    auction_params = string_params_for(:auction, vessel: vessel, fuel: fuel, port: port)
    auction_params = Map.update!(auction_params, "auction_start", fn(_) ->
      DateTime.utc_now
      |> DateTime.to_unix
      |> to_string
    end)
    authed_conn = login_user(build_conn(), user)
    auction = insert(:auction, vessel: vessel)
    {:ok, conn: authed_conn, valid_auction_params: auction_params, auction: auction, user: user}
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

    test "vessels are filtered by logged in users company", %{conn: conn, user: user} do
      conn = get(conn, auction_path(conn, :new))
      assert conn.assigns[:vessels] == Auctions.vessels_for_buyer(user)
    end
  end

  describe "create auction" do
    setup(%{user: user}) do
      port = insert(:port)
      invalid_attrs = Map.merge(@invalid_attrs, %{port_id: port.id, buyer_id: user.id})
      {:ok, %{invalid_attrs: invalid_attrs}}
    end

    test "redirects to show when data is valid", %{conn: conn, valid_auction_params: valid_auction_params, user: user} do
      conn = post conn, auction_path(conn, :create), auction: valid_auction_params

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == auction_path(conn, :show, id)

      auction = Oceanconnect.Repo.get(Auctions.Auction, id) |> Oceanconnect.Repo.preload(:vessel)
      conn = get conn, auction_path(conn, :show, id)
      assert html_response(conn, 200) =~ auction.vessel.name
      assert auction.buyer_id == user.id
    end

    #TODO Refactor test to assert on specific errors
    test "renders errors when data is invalid", %{conn: conn, invalid_attrs: invalid_attrs} do
      conn = post conn, auction_path(conn, :create), auction: invalid_attrs

      assert conn.assigns[:auction] == struct(Auctions.Auction, invalid_attrs) |> Auctions.fully_loaded
      assert html_response(conn, 200) =~ "New Auction"
    end
  end

  describe "start auction" do
    test "manually starting an auction", (%{auction: %Oceanconnect.Auctions.Auction{id: auction_id}, conn: conn}) do
      {:ok, _pid} = Oceanconnect.Auctions.AuctionsSupervisor.start_child(auction_id)
      new_conn = get(conn, auction_path(conn, :start, auction_id))

      assert redirected_to(new_conn, 302) == "/auctions"
    end
  end

  describe "edit auction" do
    test "renders form for editing chosen auction", %{conn: conn, auction: auction} do
      conn = get conn, auction_path(conn, :edit, auction)
      assert html_response(conn, 200) =~ "Edit Auction"
    end
  end

  describe "update auction" do
    test "renders form for editing chosen auction", %{conn: conn, auction: auction} do
      conn = get conn, auction_path(conn, :edit, auction)
      assert html_response(conn, 200) =~ "Edit Auction"
    end

    test "redirects when data is valid", %{conn: conn, auction: auction} do
      conn = put conn, auction_path(conn, :update, auction), auction: @update_attrs
      assert redirected_to(conn) == auction_path(conn, :show, auction)

      conn = get conn, auction_path(conn, :show, auction)
      assert html_response(conn, 200) =~ "updated PO text"
    end

    test "renders errors when data is invalid", %{conn: conn, auction: auction} do
      conn = put conn, auction_path(conn, :update, auction), auction: @invalid_attrs
      assert html_response(conn, 200) =~ "Edit Auction"
    end
  end
end
