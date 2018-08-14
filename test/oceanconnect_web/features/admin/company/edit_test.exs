defmodule Oceanconnect.Admin.Company.EditTest do
	use Oceanconnect.FeatureCase
	alias Oceanconnect.Admin.Company.{IndexPage, EditPage}

	hound_session()

	setup do
		admin_user = insert(:user, is_admin: true)
		user = insert(:user, is_admin: false)
		company = insert(:company)
		login_user(admin_user)
		{:ok, %{admin_user: admin_user, company: company, user: user}}
	end

	describe "editing companies" do
		test "visiting the admin edit company page", %{company: company} do
			EditPage.visit(company.id)

			assert EditPage.has_fields?([
				"name",
				"address1",
				"address2",
				"city",
				"country",
				"postal_code",
				"contact_name",
				"main_phone",
				"mobile_phone",
				"is_supplier"
			])
		end

		test "normal users cannot visit admin edit company page", %{user: user, company: company} do
			login_user(user)
			EditPage.visit(company.id)
			refute EditPage.is_current_path?(company.id)
		end

		test "admin can edit a company and submit the changes", %{company: company} do
			EditPage.visit(company.id)
			EditPage.fill_form(%{name: "some new name", address1: company.address1, address2: company.address2, city: company.city, country: company.country, postal_code: company.postal_code, contact_name: company.contact_name, main_phone: company.main_phone, mobile_phone: company.mobile_phone})
			EditPage.submit
			assert IndexPage.is_current_path?
			assert IndexPage.has_company_name?("some new name", company.id)
		end

		test "admin can delete a company", %{company: company} do
			EditPage.visit(company.id)
			EditPage.delete
			assert IndexPage.is_current_path?
			refute IndexPage.has_company?(company.id)
		end
	end
end
