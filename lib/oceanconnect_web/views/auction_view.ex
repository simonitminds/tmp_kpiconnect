defmodule OceanconnectWeb.AuctionView do
  use OceanconnectWeb, :view
  alias Oceanconnect.{Accounts, Auctions}
  alias Oceanconnect.Accounts.User
  alias Oceanconnect.Auctions.{Auction, AuctionBid, AuctionEvent, AuctionBarge, Barge, Fuel, Solution}

  @events_with_bid_data [:bid_placed, :auto_bid_placed, :auto_bid_triggered]
  @events_with_solution_data [:winning_solution_selected]
  @events_with_product_data [
    :bid_placed,
    :auto_bid_placed,
    :auto_bid_triggered,
    :bids_revoked
  ]
  @events_from_system [
    :duration_extended,
    :auction_state_rebuilt,
    :upcoming_auction_notified,
    :auction_ended,
    :auction_expired,
    :auction_closed
  ]
  @events_for_barges [:barge_approved, :barge_rejected, :barge_submitted, :barge_unsubmitted]

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
      auction_started: auction_map.auction_started,
      auction_ended: auction_map.auction_ended,
      auction_closed_time: auction_map.auction_closed_time,
      duration: auction_map.duration,
      decision_duration: auction_map.decision_duration,
      anonymous_bidding: auction_map.anonymous_bidding,
      additional_information: auction_map.additional_information,
      port_id: auction_map.port_id,
      buyer: auction_map.buyer,
      suppliers: auction_map.suppliers || [],
      vessel_fuels: auction_map.auction_vessel_fuels || [],
      is_traded_bid_allowed: auction_map.is_traded_bid_allowed
    }
    |> Poison.encode!()
  end

  def actual_duration(events) when is_list(events) do
    [started, ended] =
      events
      |> Enum.filter(fn event ->
        event.type in [:auction_started, :auction_ended, :auction_canceled]
      end)
      |> Enum.map(&(&1.time_entered))

    case ended do
      nil -> "—"
      _ -> "#{trunc(DateTime.diff(ended, started) / 60)} minutes"
    end
  end

  def additional_information(%Auction{additional_information: nil}), do: "—"

  def additional_information(%Auction{additional_information: additional_information}), do: additional_information

  def auction_log_suppliers(%{winning_solution: %{bids: bids}}) do
    Enum.map(bids, fn bid ->
      bid.supplier
    end)
    |> Enum.uniq()
  end

  def auction_log_suppliers(_), do: "—"

  def auction_log_vessel_fuels_by_fuel(%{auction_vessel_fuels: auction_vessel_fuels}) do
    Enum.group_by(auction_vessel_fuels, &(&1.fuel))
  end

  def auction_log_winning_solution(%{winning_solution: winning_solution}) do
    winning_solution
  end
  def auction_log_winning_solution(_), do: "—"

  def solution_from_event(%{type: :winning_solution_selected, data: %{solution: solution}}), do: solution


  def auction_log_fuel_from_id(%{fuels: fuels}, fuel_id) do
    case Enum.find(fuels, nil, &("#{&1.id}" == fuel_id)) do
      nil -> "Fuel ##{fuel_id}"
      %Fuel{name: name} -> name
    end
  end
  def auction_log_fuel_from_id(_auction, fuel_id), do: "Fuel ##{fuel_id}"

  def auction_log_supplier_from_id(%{suppliers: suppliers}, supplier_id) do
    case Enum.find(suppliers, nil, &(&1.id == supplier_id)) do
      nil -> "Supplier ##{supplier_id}"
      %{name: name} -> name
    end
  end
  def auction_log_supplier_from_id(_auction, supplier_id), do: "Supplier ##{supplier_id}"


  def bids_for_solution(%Solution{bids: bids}), do: bids

  def convert_duration(duration) do
    "#{trunc(duration / 60_000)} minutes"
  end

  def convert_date?(date_time = %{}) do
    time = "#{leftpad(date_time.hour)}:#{leftpad(date_time.minute)}:#{leftpad(date_time.second)}"
    date = "#{leftpad(date_time.day)}/#{leftpad(date_time.month)}/#{date_time.year}"
    "#{date} #{time}"
  end
  def convert_date?(_), do: "—"

  def convert_event_date_time?(date_time = %{}) do
    time =
      "#{leftpad(date_time.hour)}:#{leftpad(date_time.minute)}:#{leftpad(date_time.second)}.#{leftpad(elem(date_time.microsecond, 0), 6)}"

    date = "#{leftpad(date_time.day)}/#{leftpad(date_time.month)}/#{date_time.year}"
    "#{date} #{time}"
  end

  def convert_event_type(type) do
    ~r/_/
    |> Regex.replace(Atom.to_string(type), " ")
    |> String.capitalize()
  end
  def convert_event_type(type, _event) do
    convert_event_type(type)
  end

  def convert_event_type_extras(type, event) do
    cond do
      type in @events_for_barges ->
        barge_name_for_event(event)

      type in @events_with_product_data ->
        product_name_for_event(event)

      true ->
        ""
    end
  end

  def barge_name_for_event(%AuctionEvent{
        data: %{auction_barge: %AuctionBarge{barge: %Barge{name: name}}}
      }),
      do: name
  def barge_name_for_event(%AuctionEvent{
        data: %{auction_barge: %AuctionBarge{barge_id: barge_id}}
      }) do
    with %Barge{name: name} <- Oceanconnect.Repo.get(AuctionBarge, barge_id) do
      name
    else
      _ -> ""
    end
  end
  def barge_name_for_event(%AuctionEvent{}) do
    ""
  end

  def product_name_for_event(%AuctionEvent{
        data: %{bid: %AuctionBid{fuel_id: fuel_id}}
      }) do
    with %Fuel{name: name} <- Oceanconnect.Repo.get(Fuel, fuel_id) do
      name
    else
      _ -> ""
    end
  end
  def product_name_for_event(%AuctionEvent{
        data: %{product: fuel_id}
      }) do
    with %Fuel{name: name} <- Oceanconnect.Repo.get(Fuel, fuel_id) do
      name
    else
      _ -> ""
    end
  end
  def product_name_for_event(%AuctionEvent{}) do
    ""
  end

  def bid_is_traded?(%{is_traded_bid: true}), do: true
  def bid_is_traded?(_bid), do: false


  def event_has_bid_data?(event) do
    event.type in @events_with_bid_data
  end

  # Returns true for events that are generated by the system, rather than from
  # some interaction from a user.
  def event_is_from_system?(event) do
    event.type in @events_from_system
  end

  def event_bid_amount(%AuctionEvent{data: %{bid: %AuctionBid{amount: nil}}}), do: ""
  def event_bid_amount(%AuctionEvent{data: %{bid: %AuctionBid{amount: amount}}}) do
    "$#{:erlang.float_to_binary(amount, decimals: 2)}"
  end
  def event_bid_amount(%AuctionEvent{type: :winning_solution_selected, data: %{solution: %{normalized_price: amount}}}) do
    "$#{:erlang.float_to_binary(amount, decimals: 2)}"
  end
  def event_bid_amount(_event), do: "—"

  def event_bid_min_amount(%AuctionEvent{data: %{bid: %AuctionBid{min_amount: nil}}}), do: ""
  def event_bid_min_amount(%AuctionEvent{data: %{bid: %AuctionBid{min_amount: amount}}}) do
    "$#{:erlang.float_to_binary(amount, decimals: 2)}"
  end
  def event_bid_min_amount(_event), do: "—"

  def event_bid_is_traded?(%AuctionEvent{data: %{bid: %AuctionBid{is_traded_bid: true}}}), do: true
  def event_bid_is_traded?(_event), do: false

  def event_bid_has_amount?(%AuctionEvent{data: %{bid: %AuctionBid{amount: nil}}}), do: false
  def event_bid_has_amount?(%AuctionEvent{data: %{bid: %AuctionBid{amount: _amount}}}), do: true
  def event_bid_has_amount?(%AuctionEvent{type: :winning_solution_selected, data: %{solution: %{normalized_price: _amount}}}), do: true
  def event_bid_has_amount?(_event), do: false

  def event_bid_has_minimum?(%AuctionEvent{data: %{bid: %AuctionBid{min_amount: nil}}}), do: false
  def event_bid_has_minimum?(%AuctionEvent{data: %{bid: %AuctionBid{min_amount: _amount}}}), do: true
  def event_bid_has_minimum?(_event), do: false


  def event_company(%AuctionEvent{user: user}) when user != nil, do: user.company.name
  def event_company(%AuctionEvent{data: %{supplier: supplier}}), do: supplier
  def event_company(%AuctionEvent{data: %{bid: %{supplier_id: supplier_id}}}),
    do: Oceanconnect.Repo.get(Oceanconnect.Accounts.Company, supplier_id).name
  def event_company(%AuctionEvent{data: %{auction: %Auction{buyer: buyer}}}), do: buyer.name
  def event_company(%AuctionEvent{data: %Auction{buyer_id: buyer_id}}) do
    Oceanconnect.Repo.get(Oceanconnect.Accounts.Company, buyer_id).name
  end
  def event_company(_), do: "—"

  def event_user(%AuctionEvent{user: nil}), do: "—"
  def event_user(%AuctionEvent{user: user}), do: "#{user.first_name} #{user.last_name}"
  def event_user(_), do: "—"

  def event_template_partial_name(event) do
    cond do
      event.type in @events_from_system -> "_log_system_event.html"
      event.type in @events_with_solution_data -> "_log_solution_event.html"
      event.type in @events_with_bid_data -> "_log_bid_event.html"
      event.type in @events_for_barges -> "_log_barge_event.html"
      true -> "_log_normal_event.html"
    end
  end

  def format_price(amount) when is_float(amount) do
    "$#{:erlang.float_to_binary(amount, decimals: 2)}"
  end
  def format_price(amount), do: amount
  def user_name(%User{} = user), do: Accounts.get_user_name!(user)
  def user_name(_), do: "-"

  defp leftpad(integer, length \\ 2) do
    String.pad_leading(Integer.to_string(integer), length, "0")
  end
end
