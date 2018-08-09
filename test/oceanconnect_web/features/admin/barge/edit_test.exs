defmodule Oceanconnect.Admin.Barge.EditTest do
	use Oceanconnect.FeatureCase
	alias Oceanconnect.Admin.Barge.EditPage

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
			EditPage.submit
		end
	end
end
