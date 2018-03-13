defmodule OceanconnectWeb.Router do
  use OceanconnectWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug Guardian.Plug.Pipeline, module: Oceanconnect.Guardian,
                             error_handler: OceanconnectWeb.Api.AuthController
    plug Guardian.Plug.VerifyHeader, claims: @claims, realm: "Bearer"
    plug Guardian.Plug.EnsureAuthenticated
    plug Guardian.Plug.LoadResource, ensure: true
  end

  pipeline :authenticated do
    plug Guardian.Plug.Pipeline, module: Oceanconnect.Guardian,
                             error_handler: OceanconnectWeb.SessionController
    plug Guardian.Plug.VerifySession, claims: @claims
    plug Guardian.Plug.EnsureAuthenticated
    plug Guardian.Plug.LoadResource, ensure: true
  end

  # Other scopes may use custom stacks.
  scope "/api", OceanconnectWeb.Api do
    pipe_through :api
    get "/auctions", AuctionController, :index, as: :auction_api
    post "/auctions/:auction_id/bids", BidController, :create, as: :auction_bid_api
    get "/ports/:port_id/suppliers", PortSupplierController, :index
  end

  scope "/", OceanconnectWeb do
    pipe_through :browser # Use the default browser stack

    get "/sessions/new", SessionController, :new
    get "/", SessionController, :new
    post "/sessions", SessionController, :create

    pipe_through :authenticated # Routes requiring authentication
    delete "/sessions/logout", SessionController, :delete
    resources "/auctions", AuctionController, except: [:delete]
    get "/auctions/start/:id", AuctionController, :start
    resources "/ports", PortController
    resources "/vessels", VesselController
    resources "/fuels", FuelController
  end

end
