defmodule Oceanconnect.IndexTest do
  use Oceanconnect.FeatureCase, async: true
  alias Oceanconnect.IndexPage

  setup do
    {:ok, %{conn: build_conn()}}
  end

  test "renders the default index page", %{session: session} do
    session
    |> IndexPage.visit()

    assert IndexPage.has_title?(session, "Hello Oceanconnect!")
  end
end
