defmodule OceanconnectWeb.Router do
  use OceanconnectWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  pipeline :authenticated do
    plug(Oceanconnect.Guardian.AuthPipeline)
  end

  # Other scopes may use custom stacks.
  scope "/api", OceanconnectWeb.Api do
    pipe_through(:api)
    # Routes requiring authentication
    pipe_through(:authenticated)
    get("/auctions", AuctionController, :index, as: :auction_api)
    post("/auctions/:auction_id/bids", BidController, :create, as: :auction_bid_api)
    post("/auctions/:auction_id/port_agent", PortAgentController, :update, as: :port_agent_api)

    post(
      "/auctions/:auction_id/bids/:bid_id/select",
      BidController,
      :select_bid,
      as: :auction_bid_api
    )

    post("/auctions/:auction_id/barges/:barge_id/submit", AuctionBargesController, :submit, as: :auction_barges_api_submit)
    post("/auctions/:auction_id/barges/:barge_id/unsubmit",  AuctionBargesController, :unsubmit, as: :auction_barges_api_unsubmit)
    post("/auctions/:auction_id/barges/:barge_id/approve", AuctionBargesController, :approve, as: :auction_barges_api_approve)

    get("/ports/:port_id/suppliers", PortSupplierController, :index)
    get("/companies/:company_id/barges", CompanyBargesController, :index, as: :company_barges_api)
  end

  scope "/", OceanconnectWeb do
    # Use the default browser stack
    pipe_through(:browser)

    get("/sessions/new", SessionController, :new)
    get("/", SessionController, :new)
    post("/sessions", SessionController, :create)

    # Routes requiring authentication
    pipe_through(:authenticated)
    delete("/sessions/logout", SessionController, :delete)
    resources("/auctions", AuctionController, except: [:delete])
    get("/auctions/:id/log", AuctionController, :log)
    get("/auctions/:id/start", AuctionController, :start)
    resources("/ports", PortController)
    resources("/vessels", VesselController)
    resources("/fuels", FuelController)
  end
end
