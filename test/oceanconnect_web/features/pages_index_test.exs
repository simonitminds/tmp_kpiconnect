defmodule Oceanconnect.PageFeature do
  use Oceanconnect.Web.FeatureCase
  use Hound.Helpers
  alias Oceanconnect.IndexPage

  test "renders the default index page" do
    IndexPage.visit()
    assert IndexPage.has_title?("Hello Oceanconnect!")
  end
end
