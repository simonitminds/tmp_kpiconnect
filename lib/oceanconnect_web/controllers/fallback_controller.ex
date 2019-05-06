defmodule OceanconnectWeb.ErrorController do
  use OceanconnectWeb, :controller

  def call(conn, _) do
    conn
    |> put_flash(:error, "Something went wrong.")
    |> put_status(404)
    |> render("404.html")
  end
end
