defmodule Oceanconnect.IndexPage do
  use Oceanconnect.FeatureCase, async: true

  import Wallaby.Query, only: [css: 2]

  test "renders the default index page", %{session: session} do
    session
    |> visit("/")

    assert page_title(session) == "Hello Oceanconnect!"
  end
end
