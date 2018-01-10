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
  end

  scope "/", OceanconnectWeb do
    pipe_through :browser # Use the default browser stack

    get "/", SessionController, :new
    get "/sessions", SessionController, :new
    post "/sessions", SessionController, :create
    resources "/auctions", AuctionController, except: [:delete]
    resources "/ports", PortController
    resources "/vessels", VesselController
    resources "/fuels", FuelController
  end

  # Other scopes may use custom stacks.
  # scope "/api", OceanconnectWeb do
  #   pipe_through :api
  # end
end
