defmodule Oceanconnect.Notifications.Emails.TwoFactorAuthTest do
  use Oceanconnect.DataCase
  alias Oceanconnect.Notifications.Emails.TwoFactorAuth

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
      [two_factor_auth_email] = TwoFactorAuth.generate(user, one_time_pass)

      assert two_factor_auth_email.to.id == user.id
      assert two_factor_auth_email.assigns.one_time_pass == one_time_pass
    end
  end
end
