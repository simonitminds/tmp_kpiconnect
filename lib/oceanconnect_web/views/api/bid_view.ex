defmodule OceanconnectWeb.Api.BidView do
  use OceanconnectWeb, :view

  def render("show.json", %{success: false, message: message, bid: bid_params}) do
    %{success: false, message: message, bid: bid_params}
  end

  def render("show.json", %{success: success, message: message}) do
    %{success: success, message: message}
  end
end
