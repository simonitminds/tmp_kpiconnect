defmodule OceanconnectWeb.PageController do
  use OceanconnectWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
