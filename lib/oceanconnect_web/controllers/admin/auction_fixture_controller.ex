defmodule OceanconnectWeb.Admin.AuctionFixtureController do
  use OceanconnectWeb, :controller
  alias Oceanconnect.Auctions
  alias Oceanconnect.Deliveries
  alias Oceanconnect.Auctions.{AuctionFixture, Auction}
  alias OceanconnectWeb.Plugs.Auth

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def show(conn, %{"auction_id" => auction_id}) do
    auction = Auctions.get_auction!(auction_id)
    status = Auctions.get_auction_status!(auction)

    if status in [:closed, :expired] do
      auction_fixtures = Auctions.fixtures_for_auction(auction)
      render(conn, "show.html", %{fixtures: auction_fixtures, auction: auction})
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
        |> redirect(to: admin_auction_fixtures_path(conn, :index))

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
        |> redirect(to: admin_auction_fixtures_path(conn, :index))

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

  def delete(conn, %{"auction_id" => auction_id, "fixture_id" => fixture_id}) do
    with %{is_admin: true} <- Auth.current_user(conn),
         %Auction{vessels: vessels, port: port, buyer_id: buyer_id} = auction <- Auctions.get_auction!(auction_id),
         status when status in [:closed, :expired] <- Auctions.get_auction_status!(auction),
         %AuctionFixture{id: id} = fixture <- Auctions.get_fixture!(fixture_id),
         claims <- Deliveries.claims_for_auction(auction),
         fixture_ids_for_claims <- Enum.map(claims, & &1.fixture_id),
         false <- id in fixture_ids_for_claims do

      suppliers = Auctions.supplier_list_for_port(port, buyer_id)
      fuels = Auctions.list_all_fuels()

      case Auctions.delete_fixture(fixture) do
       {:ok, _fixture} ->
          conn
          |> put_flash(:info, "Fixture deleted successfully.")
          |> redirect(to: admin_auction_fixtures_path(conn, :index))
        {:error, changeset} ->
          conn
          |> put_flash(:warning, "Something went wrong!")
          |> render("edit.hmtl",
            fixture: fixture,
            changeset: changeset,
            auction: auction,
            suppliers: suppliers,
            fuels: fuels,
            vessels: vessels
          )
      end
    else
      _ ->
        conn
        |> put_flash(:info, "Fixture could not be deleted. There may be a claim open against it.")
        |> redirect(to: admin_auction_fixtures_path(conn, :index))
    end
  end
end
