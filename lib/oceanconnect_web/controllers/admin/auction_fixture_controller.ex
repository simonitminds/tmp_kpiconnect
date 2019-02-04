defmodule OceanconnectWeb.Admin.AuctionFixtureController do
  use OceanconnectWeb, :controller
  alias Oceanconnect.Auctions

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
end
