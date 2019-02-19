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
    plug(Guardian.Plug.VerifySession, key: :admin, allow_blank: true)
    plug(Guardian.Plug.VerifyHeader, key: :admin, allow_blank: true)
    plug(Guardian.Plug.LoadResource, key: :admin, allow_blank: true)
  end

  pipeline :admin_required do
    plug(OceanconnectWeb.Plugs.CheckAdmin)
  end


  scope "/api", OceanconnectWeb.Api do
    pipe_through(:api)
    # Routes requiring authentication
    pipe_through(:authenticated)
    get("/auctions", AuctionController, :index, as: :auction_api)
    get("/auctions/:auction_id", AuctionController, :show, as: :auction_api)
    post("/auctions/:auction_id/bids", BidController, :create, as: :auction_bid_api)
    post("/auctions/:auction_id/revoke_bid", BidController, :revoke, as: :auction_bid_api)

    post(
      "/auctions/:auction_id/submit_comment",
      AuctionCommentsController,
      :create,
      as: :auction_comments_api
    )

    post(
      "/auctions/:auction_id/select_solution",
      BidController,
      :select_solution,
      as: :auction_bid_api
    )

    post(
      "/auctions/:auction_id/barges/:barge_id/submit",
      AuctionBargesController,
      :submit,
      as: :auction_barges_api_submit
    )

    post(
      "/auctions/:auction_id/barges/:barge_id/unsubmit",
      AuctionBargesController,
      :unsubmit,
      as: :auction_barges_api_unsubmit
    )

    post(
      "/auctions/:auction_id/barges/:barge_id/:supplier_id/approve",
      AuctionBargesController,
      :approve,
      as: :auction_barges_api_approve
    )

    post(
      "/auctions/:auction_id/barges/:barge_id/:supplier_id/reject",
      AuctionBargesController,
      :reject,
      as: :auction_barges_api_reject
    )

    get("/ports/:port_id/suppliers", PortSupplierController, :index)
    get("/companies/:company_id/barges", CompanyBargesController, :index, as: :company_barges_api)
  end

  scope "/", OceanconnectWeb do
    # Use the default browser stack
    pipe_through(:browser)

    get("/registration", RegistrationController, :new)
    post("/registration", RegistrationController, :create)

    get("/sessions/new", SessionController, :new)
    get("/", SessionController, :new)
    post("/sessions", SessionController, :create)
    get("/sessions/new/two_factor_auth", TwoFactorAuthController, :new)
    post("/sessions/new/two_factor_auth", TwoFactorAuthController, :create)
    post("/sessions/new/two_factor_auth/resend_email", TwoFactorAuthController, :resend_email)

    get("/forgot_password", ForgotPasswordController, :new)
    post("/forgot_password", ForgotPasswordController, :create)

    get("/reset_password", ForgotPasswordController, :edit)
    post("/reset_password", ForgotPasswordController, :update)

    # Routes requiring authentication
    pipe_through(:authenticated)

    post(
      "/sessions/stop_impersonating",
      SessionController,
      :stop_impersonating,
      as: :admin_stop_impersonating_session
    )

    delete("/sessions/logout", SessionController, :delete)
    get("/auctions/t:id", TermAuctionController, :show)
    # post("/auctions", TermAuctionController, :create)
    resources("/auctions", AuctionController, except: [:delete])
    get("/auctions/:id/log", AuctionController, :log)
    get("/auctions/:id/start", AuctionController, :start)
    get("/auctions/:id/cancel", AuctionController, :cancel)
    get("/auctions/:id/rsvp", AuctionRsvpController, :update, as: :auction_rsvp)
    resources("/ports", PortController)
    resources("/vessels", VesselController)
    resources("/fuels", FuelController)

    resources("/users", UserController)
    post("/users/:user_id/reset_password", UserController, :reset_password)

    # TODO: remove this after emails are designed
    post("/send_email/invitation", EmailController, :send_invitation)
    post("/send_email/upcoming", EmailController, :send_upcoming)
    post("/send_email/cancellation", EmailController, :send_cancellation)
    post("/send_email/completion", EmailController, :send_completion)
  end

  scope "/admin", OceanconnectWeb.Admin do
    pipe_through(:browser)
    pipe_through(:authenticated)
    pipe_through(:admin_required)

    post("/sessions/impersonate", SessionController, :impersonate, as: :admin_impersonate_session)

    post(
      "/sessions/stop_impersonating",
      SessionController,
      :stop_impersonating,
      as: :admin_stop_impersonating_session
    )

    get("/auctions/:auction_id/fixtures", AuctionFixtureController, :index, as: :admin_auction_fixtures)
    post("/auctions/:auction_id/fixtures", AuctionFixtureController, :create, as: :admin_auction_fixture)
    put("/auctions/:auction_id/fixtures/:fixture_id", AuctionFixtureController, :update, as: :admin_auction_fixture)
    get("/auctions/:auction_id/fixtures/new", AuctionFixtureController, :new, as: :admin_auction_fixture)
    get("/auctions/:auction_id/fixtures/:fixture_id/edit", AuctionFixtureController, :edit, as: :admin_auction_fixture)

    resources("/vessels", VesselController, as: :admin_vessel)
    post("/vessels/:vessel_id/deactivate", VesselController, :deactivate, as: :admin_vessel)
    post("/vessels/:vessel_id/activate", VesselController, :activate, as: :admin_vessel)

    resources("/users", UserController, as: :admin_user)
    post("/users/:user_id/deactivate", UserController, :deactivate, as: :admin_user)
    post("/users/:user_id/activate", UserController, :activate, as: :admin_user)
    post("/users/:user_id/reset_password", UserController, :reset_password, as: :admin_user)

    resources("/companies", CompanyController, as: :admin_company)
    post("/companies/:company_id/deactivate", CompanyController, :deactivate, as: :admin_company)
    post("/companies/:company_id/activate", CompanyController, :activate, as: :admin_company)

    resources("/barges", BargeController, as: :admin_barge)
    post("/barges/:barge_id/deactivate", BargeController, :deactivate, as: :admin_barge)
    post("/barges/:barge_id/activate", BargeController, :activate, as: :admin_barge)

    resources("/fuels", FuelController, as: :admin_fuel)
    post("/fuels/:fuel_id/deactivate", FuelController, :deactivate, as: :admin_fuel)
    post("/fuels/:fuel_id/activate", FuelController, :activate, as: :admin_fuel)

    resources("/ports", PortController, as: :admin_port)
    post("/ports/:port_id/deactivate", PortController, :deactivate, as: :admin_port)
    post("/ports/:port_id/activate", PortController, :activate, as: :admin_port)
  end

  # TODO: remove this when finished designing emails
  if Mix.env() == :dev do
    forward("/sent_emails", Bamboo.SentEmailViewerPlug)
  end
end
