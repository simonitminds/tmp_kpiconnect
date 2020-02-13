defmodule Oceanconnect.Notifications.Emails.UserInterestTest do
  use Oceanconnect.DataCase
  alias Oceanconnect.Notifications.Emails.UserInterest

  describe "registration emails" do
    setup do
      user = insert(:user)

      {:ok, %{user: user}}
    end

    test "user interest email builds for admin", %{user: user} do
      new_user_info = %{
        email: user.email,
        first_name: user.first_name,
        last_name: user.last_name,
        company_name: user.company.name,
        office_phone: user.office_phone,
        mobile_phone: user.mobile_phone
      }

      [user_interest_email] = UserInterest.generate(new_user_info)

      assert user_interest_email.to == "nbolton@oceanconnectmarine.com"
      assert user_interest_email.assigns.new_user_info == new_user_info
    end
  end
end
