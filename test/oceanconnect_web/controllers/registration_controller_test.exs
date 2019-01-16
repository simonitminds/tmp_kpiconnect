defmodule OceanconnectWeb.RegistrationControllerTest do
  use OceanconnectWeb.ConnCase

  setup do
    user = insert(:user)

    {:ok, %{user: user, conn: build_conn()}}
  end

  test "visiting the registration page", %{conn: conn} do
    response = get(conn, "/registration")
    assert html_response(response, 200) =~ "/registration"
  end

  test "submitting valid data to registration", %{conn: conn, user: user} do
    response = post(conn, "/registration", %{email: user.email, company_name: user.company.name, first_name: user.first_name, last_name: user.last_name, office_phone: user.office_phone, mobile_phone: user.mobile_phone})
    assert html_response(response, 302) =~ "/sessions/new"
  end
end
