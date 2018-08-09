defmodule Oceanconnect.Admin.Vessel.IndexTest do
	use Oceanconnect.FeatureCase
	alias Oceanconnect.Admin.Vessel.IndexPage

	hound_session()

	setup do
		admin_user = insert(:user, %{is_admin: true})
		user = insert(:user)
		vessels = insert_list(2, :vessel)
		{:ok, admin_user: admin_user, user: user, vessels: vessels}
	end

	describe "vessels" do
		test "renders the company index page for admins", %{admin_user: admin_user, vessels: vessels} do
			login_user(admin_user)
			IndexPage.visit
			assert IndexPage.is_current_path?()
			assert IndexPage.has_vessels?(vessels)
		end

		test "company index page does not render for regular vessels", %{user: user} do
			login_user(user)
			IndexPage.visit
			refute IndexPage.is_current_path?()
		end

		test "admin can deactivate a vessel grade", %{admin_user: admin_user, vessels: vessels} do
			login_user(admin_user)
			IndexPage.visit
			assert IndexPage.is_current_path?()
			assert IndexPage.has_vessels?(vessels)

			[vessel, _] = vessels
			IndexPage.deactivate_vessel(vessel)
			assert IndexPage.is_vessel_inactive?(vessel)
		end

		test "admin can activate a vessel grade", %{admin_user: admin_user, vessels: vessels} do
			login_user(admin_user)
			IndexPage.visit
			assert IndexPage.is_current_path?()
			assert IndexPage.has_vessels?(vessels)

			[vessel, _] = vessels
			IndexPage.deactivate_vessel(vessel)
			assert IndexPage.is_vessel_active?(vessel)
		end
	end
end
