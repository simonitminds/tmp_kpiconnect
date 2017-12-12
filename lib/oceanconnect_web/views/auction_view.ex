defmodule OceanconnectWeb.AuctionView do
  use OceanconnectWeb, :view

  def format_datetime(nil) do
    ""
  end

  def format_datetime(date) do
    Timex.format!(date, "%m/%d/%y %R", :strftime)
  end
end
