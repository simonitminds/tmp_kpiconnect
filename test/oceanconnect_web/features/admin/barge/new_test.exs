defmodule Oceanconnect.Admin.Barge.NewTest do
  use Oceanconnect.FeatureCase
  alias Oceanconnect.Admin.Barge.{IndexPage, EditPage, NewPage}

  hound_session()

  setup do
    admin_user = insert(:user, is_admin: true)
    user = insert(:user, is_admin: false)
    port = insert(:port)
    login_user(admin_user)
    {:ok, %{admin_user: admin_user, user: user, port: port}}
  end

  describe "creating barges" do
    test "visiting the admin new barge page" do
      NewPage.visit()

      assert EditPage.has_fields?([
               "name",
               "imo_number",
               "dwt",
               "port_id"
             ])
    end

    test "normal users cannot visit admin new barge page", %{user: user} do
      login_user(user)
      NewPage.visit()
      refute NewPage.is_current_path?()
    end

    test "admin can create a new barge", %{port: port} do
      NewPage.visit()

      EditPage.fill_form(%{
        name: "some new name",
        imo_number: "1234567",
        dwt: "1234",
        port_id: port.id
      })

      EditPage.submit()
      assert IndexPage.is_current_path?()
      assert IndexPage.has_barge_name?("some new name")
    end
  end
end
