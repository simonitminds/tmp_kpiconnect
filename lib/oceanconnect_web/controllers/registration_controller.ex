defmodule OceanconnectWeb.RegistrationController do
  use OceanconnectWeb, :controller
  import Plug.Conn

  def new(conn, _), do: render(conn, "user_interest.html")

  def create(conn, %{"email" => email} = new_user_information) do
    case email do
      nil ->
        conn
        |> put_flash(:error, "Please make sure to include your email address!")
        |> put_status(401)
        |> render("user_interest.html")

      _ ->
        Oceanconnect.Auctions.NonEventNotifier.emit(:user_interest, new_user_information)

        conn
        |> put_flash(
          :info,
          "Thank you for expressing interest in OceanConnect Marine. You will be contacted by an auction administrator."
        )
        |> put_status(302)
        |> redirect(to: session_path(conn, :new))
    end
  end
end
