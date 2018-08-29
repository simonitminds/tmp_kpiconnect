defmodule Oceanconnect.Admin.Company.IndexTest do
	use Oceanconnect.FeatureCase
	alias Oceanconnect.Admin.Company.IndexPage

	hound_session()

	setup do
		admin_user = insert(:user, %{is_admin: true})
		user = insert(:user)
		active_company = insert(:company, is_active: true)
    inactive_company = insert(:company, is_active: false)
		{:ok, admin_user: admin_user, user: user, active_company: active_company, inactive_company: inactive_company}
	end

	describe "companies" do
		test "renders the company index page for admins", %{admin_user: admin_user, active_company: active_company, inactive_company: inactive_company} do
			login_user(admin_user)
			IndexPage.visit
			assert IndexPage.is_current_path?()
			assert IndexPage.has_companies?([active_company, inactive_company])
		end

		test "company index page does not render for regular companies", %{user: user} do
			login_user(user)
			IndexPage.visit
			refute IndexPage.is_current_path?()
		end

		test "admin can deactivate a company", %{admin_user: admin_user, active_company: active_company, inactive_company: inactive_company} do
			login_user(admin_user)
			IndexPage.visit
			assert IndexPage.is_current_path?()
			assert IndexPage.has_companies?([active_company, inactive_company])

			IndexPage.deactivate_company(active_company)
			assert IndexPage.is_company_inactive?(active_company)
		end

		test "admin can activate a company", %{admin_user: admin_user, active_company: active_company, inactive_company: inactive_company} do
			login_user(admin_user)
			IndexPage.visit
			assert IndexPage.is_current_path?()
			assert IndexPage.has_companies?([active_company, inactive_company])

			IndexPage.activate_company(inactive_company)
			assert IndexPage.is_company_active?(inactive_company)
		end
	end
end
