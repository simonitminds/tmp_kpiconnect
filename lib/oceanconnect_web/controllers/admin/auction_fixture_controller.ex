defmodule OceanconnectWeb.Admin.AuctionFixtureController do
  use OceanconnectWeb, :controller
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{AuctionFixture, Auction}

  def index(conn, %{"auction_id" => auction_id}) do
    auction = Auctions.get_auction!(auction_id)
    status = Auctions.get_auction_status!(auction)
    if status in [:closed, :expired] do
       auction_fixtures = Auctions.fixtures_for_auction(auction)
      render(conn, "index.html", %{fixtures: auction_fixtures, auction: auction})
    else
      redirect(conn, to: auction_path(conn, :index))
    end
  end

  def new(conn, %{"auction_id" => auction_id}) do
    auction = Auctions.get_auction!(auction_id)
    %Auction{port: port, buyer_id: buyer_id, vessels: vessels} = auction

    status = Auctions.get_auction_status!(auction)
    changeset = Auctions.change_fixture(%AuctionFixture{})
    suppliers = Auctions.supplier_list_for_port(port, buyer_id)
    fuels = Auctions.list_all_fuels()

    if status in [:closed, :expired] do
      render(conn, "new.html", %{
        auction: auction,
        suppliers: suppliers,
        fuels: fuels,
        vessels: vessels,
        changeset: changeset
      })
    else
      redirect(conn, to: auction_path(conn, :index))
    end
  end

  def create(conn, %{
        "auction_id" => auction_id,
        "auction_fixture" => fixture_params
      }) do
    auction = Auctions.get_auction!(auction_id)
    %Auction{port: port, buyer_id: buyer_id, vessels: vessels} = auction

    status = Auctions.get_auction_status!(auction)
    unless status in [:closed, :expired] do
      redirect(conn, to: auction_path(conn, :index))
    end

    suppliers = Auctions.supplier_list_for_port(port, buyer_id)
    fuels = Auctions.list_all_fuels()

    case Auctions.create_fixture(auction_id, fixture_params) do
      {:ok, _fixture} ->
        conn
        |> put_flash(:info, "Fixture updated successfully.")
        |> redirect(to: admin_auction_fixtures_path(conn, :index, auction))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html",
          changeset: changeset,
          auction: auction,
          suppliers: suppliers,
          fuels: fuels,
          vessels: vessels
        )
    end
  end

  def edit(conn, %{"auction_id" => auction_id, "fixture_id" => fixture_id}) do
    auction = Auctions.get_auction!(auction_id)
    %Auction{port: port, buyer_id: buyer_id, vessels: vessels} = auction

    status = Auctions.get_auction_status!(auction)
    fixture = Auctions.get_fixture!(fixture_id)
    suppliers = Auctions.supplier_list_for_port(port, buyer_id)
    fuels = Auctions.list_all_fuels()

    changeset = Auctions.change_fixture(fixture)
    if status in [:closed, :expired] do

      render(conn, "edit.html", %{
        auction: auction,
        fixture: fixture,
        changeset: changeset,
        suppliers: suppliers,
        vessels: vessels,
        fuels: fuels
      })
    else
      redirect(conn, to: auction_path(conn, :index))
    end
  end

  def update(conn, %{
        "auction_id" => auction_id,
        "fixture_id" => fixture_id,
        "auction_fixture" => fixture_params
      }) do
    auction = Auctions.get_auction!(auction_id)
    %Auction{port: port, buyer_id: buyer_id, vessels: vessels} = auction

    status = Auctions.get_auction_status!(auction)
    unless status in [:closed, :expired] do
      redirect(conn, to: auction_path(conn, :index))
    end
    fixture = Auctions.get_fixture!(fixture_id)
    suppliers = Auctions.supplier_list_for_port(port, buyer_id)
    fuels = Auctions.list_all_fuels()
    case Auctions.update_fixture(fixture, fixture_params) do
      {:ok, _fixture} ->
        conn
        |> put_flash(:info, "Fixture updated successfully.")
        |> redirect(to: admin_auction_fixtures_path(conn, :index, auction))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html",
          fixture: fixture,
          changeset: changeset,
          auction: auction,
          suppliers: suppliers,
          fuels: fuels,
          vessels: vessels
        )
    end
  end
end