defmodule Oceanconnect.Admin.Vessel.EditTest do
	use Oceanconnect.FeatureCase
	alias Oceanconnect.Admin.Vessel.{IndexPage, EditPage}

	hound_session()

	setup do
		admin_user = insert(:user, is_admin: true)
		user = insert(:user, is_admin: false)
		vessel = insert(:vessel)
		login_user(admin_user)
		{:ok, %{admin_user: admin_user, vessel: vessel, user: user}}
	end

	describe "editing vessels" do
		test "visiting the admin edit vessel page", %{vessel: vessel} do
			EditPage.visit(vessel.id)

			assert EditPage.has_fields?([
				"name",
				"imo"
			])
		end

		test "normal users cannot visit admin edit vessel page", %{user: user, vessel: vessel} do
			login_user(user)
			EditPage.visit(vessel.id)
			refute EditPage.is_current_path?(vessel.id)
		end

		test "admin can edit a vessel and submit the changes", %{vessel: vessel} do
			EditPage.visit(vessel.id)
			EditPage.fill_form(%{name: "some new name", imo: vessel.imo})
			EditPage.submit
			assert IndexPage.is_current_path?
			assert IndexPage.has_vessel_name?("some new name")
		end

		test "admin can delete a vessel", %{vessel: vessel} do
			EditPage.visit(vessel.id)
			EditPage.delete
			assert IndexPage.is_current_path?
			refute IndexPage.has_vessel?(vessel.id)
		end
	end
end
