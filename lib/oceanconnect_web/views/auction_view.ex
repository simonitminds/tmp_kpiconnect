defmodule OceanconnectWeb.AuctionView do
  use OceanconnectWeb, :view

  def format_datetime(nil) do
    ""
  end

  def format_datetime(date) do
    Timex.format!(date, "%m/%d/%y %R", :strftime)
  end

  def auction_from_changeset(struct) do
    struct
    |> Map.from_struct()
    |> Map.delete(:__meta__)
  end
end
