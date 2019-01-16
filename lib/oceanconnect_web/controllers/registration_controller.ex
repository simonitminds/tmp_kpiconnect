defmodule OceanconnectWeb.RegistrationController do
  use OceanconnectWeb, :controller
  import Plug.Conn

  def new(conn, _), do: render(conn, "user_interest.html")

  def create(conn, new_user_information) do
    Enum.map(
      Map.to_list(new_user_information), fn {k, v} ->
        if v == nil and k in ["email", "company_name", "first_name", "last_name"] do
          case k do
            "email" ->
              error = "Please make sure to include your email"
              conn
              |> put_flash(:error, error)
              |> put_status(401)
              |> render("user_interest.html")
            "company_name" ->
              error = "Please make sure to include your company's name"
              conn
              |> put_flash(:error, error)
              |> put_status(401)
              |> render("user_interest.html")
            "first_name" ->
              error = "Please make sure to include your first name"
              conn
              |> put_flash(:error, error)
              |> put_status(401)
              |> render("user_interest.html")
            "last_name" ->
              error = "Please make sure to include your last name"
              conn
              |> put_flash(:error, error)
              |> put_status(401)
              |> render("user_interest.html")
          end
        end
      end
    )

    OceanconnectWeb.Email.user_interest(new_user_information)
    |> OceanconnectWeb.Mailer.deliver_later()

    conn
    |> put_flash(:info, "Thank you for expressing interest in OceanConnect Marine. You will be contacted by a site administrator.")
    |> put_status(302)
    |> redirect(to: session_path(conn, :new))
  end
end
