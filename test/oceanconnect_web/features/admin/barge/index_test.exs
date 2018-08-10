defmodule Oceanconnect.Admin.Barge.IndexTest do
	use Oceanconnect.FeatureCase
	alias Oceanconnect.Admin.Barge.IndexPage

	hound_session()

	setup do
		admin_user = insert(:user, %{is_admin: true})
		user = insert(:user)
		barges = insert_list(2, :barge)
		{:ok, admin_user: admin_user, user: user, barges: barges}
	end

	describe "barges" do
		test "renders the company index page for admins", %{admin_user: admin_user, barges: barges} do
			login_user(admin_user)
			IndexPage.visit
			assert IndexPage.is_current_path?()
			assert IndexPage.has_barges?(barges)
		end

		test "company index page does not render for regular barges", %{user: user} do
			login_user(user)
			IndexPage.visit
			refute IndexPage.is_current_path?()
		end

		test "admin can deactivate a barge grade", %{admin_user: admin_user, barges: barges} do
			login_user(admin_user)
			IndexPage.visit
			assert IndexPage.is_current_path?()
			assert IndexPage.has_barges?(barges)

			[barge, _] = barges
			IndexPage.deactivate_barge(barge)
			assert IndexPage.is_barge_inactive?(barge)
		end

		test "admin can activate a barge grade", %{admin_user: admin_user, barges: barges} do
			login_user(admin_user)
			IndexPage.visit
			assert IndexPage.is_current_path?()
			assert IndexPage.has_barges?(barges)

			[barge, _] = barges
			IndexPage.deactivate_barge(barge)
			assert IndexPage.is_barge_active?(barge)
		end
	end
end
