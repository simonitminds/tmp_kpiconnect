defmodule OceanconnectWeb.EmailTest do
  use Oceanconnect.DataCase

  alias OceanconnectWeb.Email

  describe "password reset emails" do
    setup do
      user = insert(:user)

      {:ok, %{user: user}}
    end

    test "password reset email builds for the inputted user", %{user: user} do
      {:ok, token, _claims} = Oceanconnect.Guardian.encode_and_sign(user, %{email: true})
      password_reset_email = Email.password_reset(user, token)

      assert password_reset_email.to.id == user.id
      assert password_reset_email.assigns.token == token
    end
  end

  describe "two factor auth emails" do
    setup do
      user = insert(:user, %{has_2fa: true})

      token =
        :crypto.strong_rand_bytes(8)
        |> Base.encode32()

      one_time_pass = :pot.hotp(token, _num_of_trials = 1)

      {:ok, %{user: user, token: token, one_time_pass: one_time_pass}}
    end

    test "two factor auth email builds for the inputted user", %{
      user: user,
      one_time_pass: one_time_pass
    } do
      two_factor_auth_email = Email.two_factor_auth(user, one_time_pass)

      assert two_factor_auth_email.to.id == user.id
      assert two_factor_auth_email.assigns.one_time_pass == one_time_pass
    end
  end

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

      user_interest_email = Email.user_interest(new_user_info)

      assert user_interest_email.to == "nbolton@oceanconnectmarine.com"
      assert user_interest_email.assigns.new_user_info == new_user_info
    end
  end
end
