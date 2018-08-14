defmodule Oceanconnect.Admin.Fuel.NewTest do
	use Oceanconnect.FeatureCase
	alias Oceanconnect.Admin.Fuel.{IndexPage, EditPage, NewPage}

	hound_session()

	setup do
		admin_user = insert(:user, is_admin: true)
		user = insert(:user, is_admin: false)
		login_user(admin_user)
		{:ok, %{admin_user: admin_user, user: user}}
	end

	describe "creating users" do
		test "visiting the admin new user page" do
			NewPage.visit

			assert EditPage.has_fields?([
				"name"
			])
		end

		test "normal users cannot visit admin new user page", %{user: user} do
			login_user(user)
			NewPage.visit
			refute NewPage.is_current_path?
		end

		test "admin can create a new user" do
			NewPage.visit
			EditPage.fill_form(%{name: "some new name"})
			EditPage.submit
			assert IndexPage.is_current_path?
			assert IndexPage.has_fuel_name?("some new name")
		end
	end
end
