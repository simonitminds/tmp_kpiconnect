defmodule OceanconnectWeb.Api.AuctionFixtureView do
  use OceanconnectWeb, :view
  alias Oceanconnect.Auctions.Payloads.FixturePayload

  def render("index.json", %{data: fixture_payloads}) do
    %{
      data:
        Enum.map(fixture_payloads, fn fixture_payload ->
          render(__MODULE__, "fixture.json", data: fixture_payload)
        end)
    }
  end

  def render("fixture.json", %{data: fixture_payload}) do
    FixturePayload.json_from_payload(fixture_payload)
  end

  def render("show.json", %{data: fixture}) do
    %{data: fixture}
  end

  def render("show.json", %{success: success, message: message}) do
    %{success: success, message: message}
  end
end
