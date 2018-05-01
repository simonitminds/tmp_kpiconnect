defmodule OceanconnectWeb.AuctionView do
  use OceanconnectWeb, :view
  alias Oceanconnect.Auctions.{Auction, AuctionBidList, AuctionEvent}

  def actual_duration(%Auction{auction_ended: nil}), do: "-"
  def actual_duration(%Auction{auction_start: started, auction_ended: ended}) do
    "#{trunc(DateTime.diff(ended, started) / 60)} minutes"
  end

  def auction_log_supplier(%{state: %{winning_bid: %{supplier: supplier}}}) do
    supplier
  end
  def auction_log_supplier(%{state: %{winning_bid: nil}}), do: "—"

  def auction_log_winning_bid(%{state: %{winning_bid: %{amount: amount}}}) do
    "$#{:erlang.float_to_binary(amount, [decimals: 2])}"
  end
  def auction_log_winning_bid(%{state: %{winning_bid: nil}}), do: "—"

  def convert_duration(duration) do
    "#{trunc(duration / 60_000)} minutes"
  end

  def convert_date?(date_time = %{}) do
    time = "#{leftpad(date_time.hour)}:#{leftpad(date_time.minute)}:#{leftpad(date_time.second)}"
    date = "#{leftpad(date_time.day)}/#{leftpad(date_time.month)}/#{date_time.year}"
    "#{date} #{time}"
  end
  def convert_date?(_), do: "-"

  def convert_event_type(type) do
    ~r/_/
    |> Regex.replace(Atom.to_string(type), " ")
    |> String.capitalize
  end

  def event_bid_amount(%AuctionEvent{data: %{bid: %AuctionBidList.AuctionBid{amount: amount}}}) do
    "$#{:erlang.float_to_binary(amount, decimals: 2)}"
  end
  def event_bid_amount(_event), do: "-"

  def event_company(%AuctionEvent{user: user}) when user != nil, do: user.company.name
  def event_company(%AuctionEvent{data: %{supplier: supplier}}), do: supplier
  def event_company(%AuctionEvent{data: %{auction: %Auction{buyer: buyer}}}), do: buyer.name
  def event_company(%AuctionEvent{data: %Auction{buyer: buyer}}), do: buyer.name
  def event_company(_), do: "-"

  def event_user(%AuctionEvent{user: nil}), do: "-"
  def event_user(%AuctionEvent{user: user}), do: user.email
  def event_user(_), do: "-"

  defp leftpad(integer) do
    String.pad_leading(Integer.to_string(integer), 2, "0")
  end
end
