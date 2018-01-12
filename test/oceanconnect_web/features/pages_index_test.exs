defmodule Oceanconnect.IndexTest do
  use Oceanconnect.FeatureCase, async: true
  alias Oceanconnect.IndexPage

  setup do
    user = insert(:user)
    login_user(user)
    {:ok, %{auction: insert(:auction)}}
  end

  test "renders the default index page" do
    IndexPage.visit()

    assert IndexPage.has_title?("Hello Oceanconnect!")
  end
end
