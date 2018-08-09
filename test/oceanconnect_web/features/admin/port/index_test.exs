defmodule Oceanconnect.Admin.Port.IndexTest do
	use Oceanconnect.FeatureCase
	alias Oceanconnect.Admin.Port.IndexPage

	hound_session()

	setup do
		admin_user = insert(:user, %{is_admin: true})
		user = insert(:user)
		ports = insert_list(2, :port)
		{:ok, admin_user: admin_user, user: user, ports: ports}
	end

	describe "ports" do
		test "renders the company index page for admins", %{admin_user: admin_user, ports: ports} do
			login_user(admin_user)
			IndexPage.visit
			assert IndexPage.is_current_path?()
			assert IndexPage.has_ports?(ports)
		end

		test "company index page does not render for regular ports", %{user: user} do
			login_user(user)
			IndexPage.visit
			refute IndexPage.is_current_path?()
		end

		test "admin can deactivate a port", %{admin_user: admin_user, ports: ports} do
			login_user(admin_user)
			IndexPage.visit
			assert IndexPage.is_current_path?()
			assert IndexPage.has_ports?(ports)

			[port, _] = ports
			IndexPage.deactivate_port(port)
			assert IndexPage.is_port_inactive?(port)
		end

		test "admin can activate a port", %{admin_user: admin_user, ports: ports} do
			login_user(admin_user)
			IndexPage.visit
			assert IndexPage.is_current_path?()
			assert IndexPage.has_ports?(ports)

			[port, _] = ports
			IndexPage.deactivate_port(port)
			assert IndexPage.is_port_active?(port)
		end
	end
end
