defmodule Oceanconnect.Admin.Barge.EditTest do
  use Oceanconnect.FeatureCase
  alias Oceanconnect.Admin.Barge.{IndexPage, EditPage}

  hound_session()

  setup do
    admin_user = insert(:user, is_admin: true)
    user = insert(:user, is_admin: false)
    barge = insert(:barge)
    login_user(admin_user)
    {:ok, %{admin_user: admin_user, barge: barge, user: user}}
  end

  describe "editing barges" do
    test "visiting the admin edit barge page", %{barge: barge} do
      EditPage.visit(barge.id)

      assert EditPage.has_fields?([
               "name",
               "imo_number",
               "dwt"
             ])
    end

    test "normal users cannot visit admin edit barge page", %{user: user, barge: barge} do
      login_user(user)
      EditPage.visit(barge.id)
      refute EditPage.is_current_path?(barge.id)
    end

    test "admin can edit a barge and submit the changes", %{barge: barge} do
      EditPage.visit(barge.id)
      EditPage.fill_form(%{name: "some new name", imo_number: barge.imo_number, dwt: barge.dwt})
      EditPage.submit()
      assert IndexPage.is_current_path?()
      assert IndexPage.has_barge_name?("some new name")
    end

    test "admin can delete a barge", %{barge: barge} do
      EditPage.visit(barge.id)
      EditPage.delete()
      assert IndexPage.is_current_path?()
      refute IndexPage.has_barge?(barge.id)
    end
  end
end
