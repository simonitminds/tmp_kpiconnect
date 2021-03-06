defmodule Oceanconnect.Admin.Port.EditTest do
  use Oceanconnect.FeatureCase
  alias Oceanconnect.Admin.Port.{IndexPage, EditPage}

  hound_session()

  setup do
    admin_user = insert(:user, is_admin: true)
    user = insert(:user, is_admin: false)
    port = insert(:port)
    companies = insert_list(2, :company)
    login_user(admin_user)
    {:ok, %{admin_user: admin_user, port: port, user: user, companies: companies}}
  end

  describe "editing ports" do
    test "visiting the admin edit port page", %{port: port} do
      EditPage.visit(port.id)

      assert EditPage.has_fields?([
               "name",
               "country",
               "companies"
             ])
    end

    test "normal users cannot visit admin edit port page", %{user: user, port: port} do
      login_user(user)
      EditPage.visit(port.id)
      refute EditPage.is_current_path?(port.id)
    end

    test "admin can edit a port and submit the changes", %{port: port, companies: companies} do
      EditPage.visit(port.id)
      EditPage.fill_form(%{name: "some new name", country: port.country, companies: companies})
      EditPage.submit()
      assert IndexPage.is_current_path?()
      assert IndexPage.has_port_name?("some new name")
    end

    test "admin can delete a port", %{port: port} do
      EditPage.visit(port.id)
      EditPage.delete()
      assert IndexPage.is_current_path?()
      refute IndexPage.has_port?(port.id)
    end

    test "admin can assign multiple companies to a port", %{port: port, companies: companies} do
      EditPage.visit(port.id)
      assert EditPage.is_current_path?(port.id)
      EditPage.add_companies(companies)
      EditPage.submit()
      assert IndexPage.is_current_path?()
      EditPage.visit(port.id)
      assert EditPage.companies_selected?(companies)
    end
  end
end
