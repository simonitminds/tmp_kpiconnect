defmodule OceanconnectWeb.Session.ResetPasswordTest do
  use Oceanconnect.FeatureCase
  alias Oceanconnect.Session.{NewPage, ResetPasswordPage}

  hound_session()
  setup do
    user = insert(:user)
    %{:ok, %{user: user}}
  end

  test "user with signed token can visit"
end
