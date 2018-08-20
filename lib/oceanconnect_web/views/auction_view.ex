defmodule OceanconnectWeb.AuctionView do
  use OceanconnectWeb, :view
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{Auction, AuctionBid, AuctionEvent, AuctionBarge, Barge}

  def auction_json_for_form(auction = %Auction{}) do
    auction_map =
      auction
      |> Auctions.strip_non_loaded()

    %{
      po: auction_map.po,
      port_agent: auction_map.port_agent,
      eta: auction_map.eta,
      etd: auction_map.etd,
      scheduled_start: auction_map.scheduled_start,
      auction_ended: auction_map.auction_ended,
      duration: auction_map.duration,
      decision_duration: auction_map.decision_duration,
      anonymous_bidding: auction_map.anonymous_bidding,
      split_bid_allowed: auction_map.split_bid_allowed,
      additional_information: auction_map.additional_information,
      port: auction_map.port,
      buyer: auction_map.buyer,
      suppliers: auction_map.suppliers || [],
      vessel_fuels: auction_map.auction_vessel_fuels || []
    }
    |> Poison.encode!()
  end

  def actual_duration(%Auction{auction_ended: nil}), do: "-"

  def actual_duration(%Auction{scheduled_start: started, auction_ended: ended}) do
    "#{trunc(DateTime.diff(ended, started) / 60)} minutes"
  end

  def auction_log_supplier(%{winning_bid: %{supplier: supplier}}) do
    supplier
  end

  def auction_log_supplier(%{winning_bid: nil}), do: "—"

  def auction_log_winning_bid(%{winning_bid: %{amount: amount}}) do
    "$#{:erlang.float_to_binary(amount, decimals: 2)}"
  end

  def auction_log_winning_bid(%{winning_bid: nil}), do: "—"

  def convert_duration(duration) do
    "#{trunc(duration / 60_000)} minutes"
  end

  def convert_date?(date_time = %{}) do
    time = "#{leftpad(date_time.hour)}:#{leftpad(date_time.minute)}:#{leftpad(date_time.second)}"
    date = "#{leftpad(date_time.day)}/#{leftpad(date_time.month)}/#{date_time.year}"
    "#{date} #{time}"
  end

  def convert_date?(_), do: "-"

  def convert_event_date_time?(date_time = %{}) do
    time =
      "#{leftpad(date_time.hour)}:#{leftpad(date_time.minute)}:#{leftpad(date_time.second)}:#{
        elem(date_time.microsecond, 0)
      }"

    date = "#{leftpad(date_time.day)}/#{leftpad(date_time.month)}/#{date_time.year}"
    "#{date} #{time}"
  end

  def convert_event_type(type) do
    ~r/_/
    |> Regex.replace(Atom.to_string(type), " ")
    |> String.capitalize()
  end

  def convert_event_type(type, event) do
    if type in [:barge_approved, :barge_rejected, :barge_submitted, :barge_unsubmitted] do
      "#{convert_event_type(type)}: #{barge_name_for_event(event)}"
    else
      convert_event_type(type)
    end
  end

  def barge_name_for_event(%AuctionEvent{
        data: %{auction_barge: %AuctionBarge{barge: %Barge{name: name}}}
      }),
      do: name

  def barge_name_for_event(%AuctionEvent{
        data: %{auction_barge: %AuctionBarge{barge_id: barge_id}}
      }) do
    with %Barge{name: name} <- Occeanconnect.Repo.get(AuctionBarge, barge_id) do
      name
    else
      _ -> ""
    end
  end

  def barge_name_for_event(event = %AuctionEvent{}) do
    ""
  end

  def event_bid_amount(%AuctionEvent{data: %{bid: %AuctionBid{amount: nil}}}), do: ""

  def event_bid_amount(%AuctionEvent{data: %{bid: %AuctionBid{amount: amount}}}) do
    "$#{:erlang.float_to_binary(amount, decimals: 2)}"
  end

  def event_bid_amount(_event), do: "-"

  def event_bid_min_amount(%AuctionEvent{data: %{bid: %AuctionBid{min_amount: nil}}}), do: ""

  def event_bid_min_amount(%AuctionEvent{data: %{bid: %AuctionBid{min_amount: amount}}}) do
    "$#{:erlang.float_to_binary(amount, decimals: 2)}"
  end

  def event_bid_min_amount(_event), do: "-"

  def event_company(%AuctionEvent{user: user}) when user != nil, do: user.company.name
  def event_company(%AuctionEvent{data: %{supplier: supplier}}), do: supplier

  def event_company(%AuctionEvent{data: %{bid: %{supplier_id: supplier_id}}}),
    do: Oceanconnect.Repo.get(Oceanconnect.Accounts.Company, supplier_id).name

  def event_company(%AuctionEvent{data: %{auction: %Auction{buyer: buyer}}}), do: buyer.name

  def event_company(%AuctionEvent{data: %Auction{buyer_id: buyer_id}}) do
    Oceanconnect.Repo.get(Oceanconnect.Accounts.Company, buyer_id).name
  end

  def event_company(_), do: "-"

  def event_user(%AuctionEvent{user: nil}), do: "-"
  def event_user(%AuctionEvent{user: user}), do: "#{user.first_name} #{user.last_name}"
  def event_user(_), do: "-"

  defp leftpad(integer) do
    String.pad_leading(Integer.to_string(integer), 2, "0")
  end
end
