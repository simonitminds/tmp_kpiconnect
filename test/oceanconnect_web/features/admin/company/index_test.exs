defmodule Oceanconnect.Admin.Company.IndexTest do
  use Oceanconnect.FeatureCase
  alias Oceanconnect.Admin.Company.IndexPage

  hound_session()

  setup do
    admin_user = insert(:user, %{is_admin: true})
    user = insert(:user)
    companies = insert_list(2, :company)
    {:ok, admin_user: admin_user, user: user, companies: companies}
  end

  describe "companies" do
    test "renders the company index page for admins", %{
      admin_user: admin_user,
      companies: companies
    } do
      login_user(admin_user)
      IndexPage.visit()
      assert IndexPage.is_current_path?()
      assert IndexPage.has_companies?(companies)
    end

    test "company index page does not render for regular companies", %{user: user} do
      login_user(user)
      IndexPage.visit()
      refute IndexPage.is_current_path?()
    end

    test "admin can deactivate a company grade", %{admin_user: admin_user, companies: companies} do
      login_user(admin_user)
      IndexPage.visit()
      assert IndexPage.is_current_path?()
      assert IndexPage.has_companies?(companies)

      [company, _] = companies
      IndexPage.deactivate_company(company)
      assert IndexPage.is_company_inactive?(company)
    end

    test "admin can activate a company grade", %{admin_user: admin_user, companies: companies} do
      login_user(admin_user)
      IndexPage.visit()
      assert IndexPage.is_current_path?()
      assert IndexPage.has_companies?(companies)

      [company, _] = companies
      IndexPage.deactivate_company(company)
      assert IndexPage.is_company_active?(company)
    end
  end
end
