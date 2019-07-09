defmodule OceanconnectWeb.Api.AuctionFixtureView do
  use OceanconnectWeb, :view
  alias Oceanconnect.Auctions.Payloads.{FixturePayload, FixtureEventPayload}

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

  def render("events.json", %{data: fixture_event_payload}) do
    FixtureEventPayload.json_from_payload(fixture_event_payload)
  end
end
