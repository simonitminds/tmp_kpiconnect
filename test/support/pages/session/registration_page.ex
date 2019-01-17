defmodule Oceanconnect.Session.RegistrationPage do
  @page_path "/registration"

  use Oceanconnect.Page

  def is_current_path? do
    current_path() == @page_path
  end

  def enter_credentials(first_name, last_name, company_name, office_phone, mobile_phone, email) do
    fill_field({:css, ".qa-first_name"}, first_name)
    fill_field({:css, ".qa-last_name"}, last_name)
    fill_field({:css, ".qa-company_name"}, company_name)
    fill_field({:css, ".qa-office_phone"}, office_phone)
    fill_field({:css, ".qa-mobile_phone"}, mobile_phone)
    fill_field({:css, ".qa-email"}, email)
  end

  def submit do
    click({:css, ".qa-submit"})
  end
end
