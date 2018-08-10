defmodule Oceanconnect.Admin.Fuel.IndexTest do
	use Oceanconnect.FeatureCase
	alias Oceanconnect.Admin.Fuel.IndexPage

	hound_session()

	setup do
		admin_user = insert(:user, %{is_admin: true})
		user = insert(:user)
		fuels = insert_list(2, :fuel)
		{:ok, admin_user: admin_user, user: user, fuels: fuels}
	end

	describe "fuels" do
		test "renders the company index page for admins", %{admin_user: admin_user, fuels: fuels} do
			login_user(admin_user)
			IndexPage.visit
			assert IndexPage.is_current_path?()
			assert IndexPage.has_fuels?(fuels)
		end

		test "company index page does not render for regular fuels", %{user: user} do
			login_user(user)
			IndexPage.visit
			refute IndexPage.is_current_path?()
		end

		test "admin can deactivate a fuel grade", %{admin_user: admin_user, fuels: fuels} do
			login_user(admin_user)
			IndexPage.visit
			assert IndexPage.is_current_path?()
			assert IndexPage.has_fuels?(fuels)

			[fuel, _] = fuels
			IndexPage.deactivate_fuel(fuel)
			assert IndexPage.is_fuel_inactive?(fuel)
		end

		test "admin can activate a fuel grade", %{admin_user: admin_user, fuels: fuels} do
			login_user(admin_user)
			IndexPage.visit
			assert IndexPage.is_current_path?()
			assert IndexPage.has_fuels?(fuels)

			[fuel, _] = fuels
			IndexPage.deactivate_fuel(fuel)
			assert IndexPage.is_fuel_active?(fuel)
		end
	end
end
