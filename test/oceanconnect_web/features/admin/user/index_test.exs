defmodule Oceanconnect.Admin.User.IndexTest do
	use Oceanconnect.FeatureCase
	alias Oceanconnect.Admin.User.IndexPage

	hound_session()

	setup do
		admin_user = insert(:user, is_admin: true)
		user = insert(:user, is_admin: false)
		users = insert_list(2, :user)
		{:ok, admin_user: admin_user, user: user, users: users}
	end

	describe "users" do
		test "renders the user index page for admins", %{admin_user: admin_user, users: users} do
			login_user(admin_user)
			IndexPage.visit()
			assert IndexPage.is_current_path?()
			assert IndexPage.has_users?(users)
		end

		test "user index page does not render for regular users", %{user: user} do
			login_user(user)
			IndexPage.visit
			refute IndexPage.is_current_path?()
		end

		test "admin can deactivate a user grade", %{admin_user: admin_user, users: users} do
			login_user(admin_user)
			IndexPage.visit
			assert IndexPage.is_current_path?()
			assert IndexPage.has_users?(users)

			[user, _] = users
			IndexPage.deactivate_user(user)
			assert IndexPage.is_user_inactive?(user)
		end

		test "admin can activate a user grade", %{admin_user: admin_user, users: users} do
			login_user(admin_user)
			IndexPage.visit
			assert IndexPage.is_current_path?()
			assert IndexPage.has_users?(users)

			[user, _] = users
			IndexPage.deactivate_user(user)
			assert IndexPage.is_user_active?(user)
		end
	end
end
