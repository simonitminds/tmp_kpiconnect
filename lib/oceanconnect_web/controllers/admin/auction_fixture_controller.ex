defmodule OceanconnectWeb.Admin.AuctionFixtureController do
  use OceanconnectWeb, :controller
  alias Oceanconnect.Auctions

  def index(conn, %{"auction_id" => auction_id}) do
    auction = Auctions.get_auction!(auction_id)
    auction_fixtures = Auctions.fixtures_for_auction(auction)
    render(conn, "index.html", %{fixtures: auction_fixtures})
  end
end
