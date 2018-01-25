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

  pipeline :authenticated do
    plug OceanconnectWeb.Plugs.Auth
    plug :put_user_token
  end

  defp put_user_token(conn, _) do
    if current_user = conn.assigns[:current_user] do
      token = Phoenix.Token.sign(conn, "user socket", current_user.id)
      assign(conn, :user_token, token)
    else
      conn
    end
  end


  # Other scopes may use custom stacks.
  scope "/api", OceanconnectWeb.Api do
    pipe_through :api
    get "/auctions", AuctionApiController, :index
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
