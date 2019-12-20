defmodule Oceanconnect.Auctions.AuctionPayload do
  import Oceanconnect.Auctions.Guards

  alias __MODULE__
  alias Oceanconnect.Auctions

  alias Oceanconnect.Auctions.{
    Auction,
    TermAuction,
    AuctionBid,
    AuctionTimer,
    AuctionSuppliers
  }

  alias Oceanconnect.Accounts

  alias Oceanconnect.Deliveries

  alias Oceanconnect.Auctions.Payloads.{BargesPayload, ProductBidsPayload, SolutionsPayload}

  defstruct time_remaining: nil,
            current_server_time: nil,
            auction: nil,
            status: :pending,
            participations: %{},
            # Supplier's bid history
            bid_history: [],
            # ProductBidPayloads built for buyer or supplier
            product_bids: %{},
            solutions: %{},
            submitted_barges: [],
            submitted_comments: [],
            claims: [],
            fixtures: [],
            observers: [],
            available_observers: []

  def get_auction_payload!(auction = %struct{}, user_id) when is_auction(struct) do
    auction_state = Auctions.get_auction_state!(auction)
    get_auction_payload!(auction, user_id, auction_state)
  end

  def get_auction_payload!(auction = %struct{}, user_id, auction_state = %state_struct{})
      when is_auction(struct) and is_auction_state(state_struct) do
    cond do
      Accounts.is_admin?(user_id) ->
        get_admin_auction_payload(auction, auction_state)

      user_id == auction.buyer_id ->
        get_buyer_auction_payload(auction, user_id, auction_state)

      is_observer(auction, user_id) ->
        get_observer_auction_payload(auction, auction_state)

      true ->
        get_supplier_auction_payload(auction, user_id, auction_state)
    end
  end

  def json_from_payload(%AuctionPayload{
        time_remaining: time_remaining,
        current_server_time: current_server_time,
        auction: auction,
        bid_history: bid_history,
        status: status,
        product_bids: product_bids,
        participations: participations,
        solutions: solutions,
        submitted_barges: submitted_barges,
        submitted_comments: submitted_comments,
        claims: claims,
        fixtures: fixtures,
        observers: observers,
        available_observers: available_observers
      }) do
    %{
      time_remaining: time_remaining,
      current_server_time: current_server_time,
      auction: auction,
      bid_history: bid_history,
      status: status,
      product_bids: product_bids,
      participations: participations,
      solutions: solutions,
      submitted_barges: submitted_barges,
      submitted_comments: submitted_comments,
      claims: claims,
      fixtures: fixtures,
      observers: observers,
      available_observers: available_observers
    }
  end

  defp is_observer(%{observers: observers}, user_id) do
    observers
    |> Enum.map(& &1.id)
    |> Enum.member?(user_id)
  end

  defp get_admin_auction_payload(auction = %{buyer_id: buyer_id, observers: observers}, state) do
    available_observers = Accounts.list_observers()

    get_auction_payload!(auction, buyer_id, state)
    |> Map.merge(%{observers: observers, available_observers: available_observers})
  end

  defp get_buyer_auction_payload(
         auction,
         buyer_id,
         state = %{submitted_comments: submitted_comments}
       ) do
    auction
    |> get_base_payload(state)
    |> get_base_buyer_payload(buyer_id, state)
    |> Map.merge(%{
      submitted_comments: submitted_comments,
      claims: Deliveries.claims_for_auction(auction),
      fixtures: auction |> Auctions.fixtures_for_auction() |> format_fixtures()
    })
  end

  defp get_observer_auction_payload(auction = %{buyer_id: buyer_id}, state) do
    auction
    |> get_base_payload(state)
    |> get_base_buyer_payload(buyer_id, state)
    |> Map.merge(%{auction: scrub_auction(auction, is_observer: true)})
  end

  defp get_supplier_auction_payload(
         auction,
         supplier_id,
         state = %{
           product_bids: product_bids,
           submitted_comments: submitted_comments
         }
       ) do
    auction
    |> get_base_payload(state)
    |> Map.merge(%{
      auction: scrub_auction(auction, supplier_id),
      participations: %{
        supplier_id => get_supplier_participation(auction.auction_suppliers, supplier_id)
      },
      solutions:
        SolutionsPayload.get_solutions_payload!(state, auction: auction, supplier: supplier_id),
      bid_history: get_bid_history(state, supplier_id, auction),
      product_bids:
        Enum.reduce(product_bids, %{}, fn {vessel_fuel_id, product_state}, acc ->
          Map.put(
            acc,
            vessel_fuel_id,
            ProductBidsPayload.get_product_bids_payload!(product_state,
              auction: auction,
              supplier: supplier_id
            )
          )
        end),
      submitted_barges:
        BargesPayload.get_barges_payload!(state.submitted_barges, supplier: supplier_id),
      submitted_comments: Enum.filter(submitted_comments, &(&1.supplier_id == supplier_id)),
      claims:
        Enum.filter(Deliveries.claims_for_auction(auction), &(&1.supplier_id == supplier_id)),
      fixtures:
        auction
        |> Auctions.fixtures_for_auction()
        |> Enum.filter(
          &(&1.supplier_id == supplier_id or &1.delivered_supplier_id == supplier_id)
        )
        |> format_fixtures()
    })
  end

  defp get_base_payload(auction, state = %{status: status}) do
    %AuctionPayload{
      time_remaining: get_time_remaining(auction, state),
      current_server_time: DateTime.utc_now(),
      auction: auction,
      status: status
    }
  end

  defp get_base_buyer_payload(
         payload = %AuctionPayload{auction: auction},
         buyer_id,
         state = %{product_bids: product_bids}
       ) do
    Map.merge(payload, %{
      auction: scrub_auction(auction, buyer_id),
      solutions:
        SolutionsPayload.get_solutions_payload!(state, auction: auction, buyer: buyer_id),
      participations: get_participations(auction),
      product_bids:
        Enum.reduce(product_bids, %{}, fn {vessel_fuel_id, product_state}, acc ->
          Map.put(
            acc,
            vessel_fuel_id,
            ProductBidsPayload.get_product_bids_payload!(product_state,
              auction: auction,
              buyer: buyer_id
            )
          )
        end),
      submitted_barges: BargesPayload.get_barges_payload!(state.submitted_barges, buyer: buyer_id)
    })
  end

  defp get_bid_history(%state_struct{product_bids: product_bids}, supplier_id, auction)
       when is_auction_state(state_struct) do
    Enum.map(product_bids, fn {_vessel_fuel_id, product_state} ->
      Enum.filter(product_state.bids, fn bid -> bid.supplier_id == supplier_id end)
    end)
    |> List.flatten()
    |> Enum.sort_by(&DateTime.to_unix(&1.time_entered, :microsecond))
    |> Enum.reverse()
    |> Enum.map(&scrub_bid_for_supplier(&1, supplier_id, auction))
  end

  defp get_supplier_participation(auction_suppliers, supplier_id) do
    with %AuctionSuppliers{participation: participation} <-
           Enum.find(auction_suppliers, fn supplier -> supplier.supplier_id == supplier_id end) do
      participation
    else
      nil -> nil
    end
  end

  defp get_participations(%struct{anonymous_bidding: true}) when is_auction(struct), do: %{}

  defp get_participations(%struct{auction_suppliers: auction_suppliers})
       when is_auction(struct) do
    auction_suppliers
    |> Enum.reduce(%{}, fn auction_supplier, acc ->
      Map.put(acc, auction_supplier.supplier_id, auction_supplier.participation)
    end)
  end

  defp get_time_remaining(auction = %struct{}, %state_struct{status: :open})
       when is_auction(struct) and is_auction_state(state_struct) do
    AuctionTimer.read_timer(auction.id, :duration)
  end

  defp get_time_remaining(auction = %struct{}, %state_struct{status: :decision})
       when is_auction(struct) and is_auction_state(state_struct) do
    AuctionTimer.read_timer(auction.id, :decision_duration)
  end

  defp get_time_remaining(_auction = %struct{}, %state_struct{})
       when is_auction(struct) and is_auction_state(state_struct),
       do: 0

  defp scrub_auction(auction = %struct{buyer_id: buyer_id}, buyer_id) when is_auction(struct),
    do: auction

  defp scrub_auction(
         %Auction{auction_vessel_fuels: auction_vessel_fuels, vessels: vessels, buyer: _buyer} =
           auction,
         is_observer: true
       ) do
    {_counter, auction_vessel_fuels} =
      auction_vessel_fuels
      |> Enum.reduce({1, []}, fn vf, acc ->
        {counter, vessel_fuels} = acc
        {counter + 1, [%{vf | vessel: scrub_vessel(vf.vessel, counter)} | vessel_fuels]}
      end)

    {_counter, vessels} =
      vessels
      |> Enum.reduce({1, []}, fn vessel, acc ->
        {counter, vessels} = acc
        {counter + 1, [scrub_vessel(vessel, counter) | vessels]}
      end)

    %{auction | auction_vessel_fuels: auction_vessel_fuels, vessels: vessels}
    |> Map.drop([:buyer, :buyer_reference_number, :additional_information])
  end

  defp scrub_auction(%TermAuction{vessels: vessels, buyer: _buyer} = auction, is_observer: true) do
    {_counter, vessels} =
      vessels
      |> Enum.reduce({1, []}, fn vessel, acc ->
        {counter, vessels} = acc
        {counter + 1, [scrub_vessel(vessel, counter) | vessels]}
      end)

    %{auction | vessels: vessels}
    |> Map.drop([:buyer, :buyer_reference_number, :additional_information])
  end

  defp scrub_auction(auction = %struct{}, _supplier_id) when is_auction(struct) do
    Map.delete(auction, :suppliers)
  end

  defp scrub_vessel(vessel, counter), do: %{vessel | name: "Vessel #{counter}", imo: 12345}

  defp scrub_bid_for_supplier(nil, _supplier_id, _auction), do: nil

  defp scrub_bid_for_supplier(
         bid = %AuctionBid{supplier_id: supplier_id},
         supplier_id,
         auction = %struct{}
       )
       when is_auction(struct) do
    %{bid | min_amount: bid.min_amount, comment: bid.comment}
    |> Map.put(:product, product_for_bid(bid, auction))
    |> Map.from_struct()
  end

  defp scrub_bid_for_supplier(bid = %AuctionBid{}, _supplier_id, auction = %struct{})
       when is_auction(struct) do
    %{bid | min_amount: nil, comment: nil, is_traded_bid: false}
    |> Map.from_struct()
    |> Map.put(:product, product_for_bid(bid, auction))
    |> Map.delete(:supplier_id)
  end

  # defp scrub_bid_for_buyer(nil, _buyer_id, _auction), do: nil
  #
  # defp scrub_bid_for_buyer(bid = %AuctionBid{}, _buyer_id, auction = %struct{})
  #      when is_auction(struct) do
  #   supplier = AuctionSuppliers.get_name_or_alias(bid.supplier_id, auction)
  #
  #   %{bid | supplier_id: nil, min_amount: nil}
  #   |> Map.from_struct()
  #   |> Map.put(:product, product_for_bid(bid, auction))
  #   |> Map.put(:supplier, supplier)
  # end

  defp product_for_bid(bid, %Auction{auction_vessel_fuels: vessel_fuels}) do
    vf = Enum.find(vessel_fuels, &("#{&1.id}" == bid.vessel_fuel_id))
    vessel = vf.vessel.name
    fuel = vf.fuel.name
    "#{fuel} for #{vessel}"
  end

  defp product_for_bid(_bid, %TermAuction{fuel: fuel}) do
    "#{fuel.name}"
  end

  defp format_fixtures(fixtures) when is_list(fixtures) do
    fixtures
    |> Enum.map(fn fixture ->
      fixture
      |> format_fixture_prices()
      |> format_fixture_quantities()
      |> Auctions.strip_non_loaded()
    end)
  end

  defp format_fixture_prices(
         %{
           price: %Decimal{} = price,
           original_price: %Decimal{} = original_price,
           delivered_price: %Decimal{} = delivered_price
         } = fixture
       ) do
    %{
      fixture
      | price: Decimal.to_string(price),
        original_price: Decimal.to_string(price),
        delivered_price: Decimal.to_string(delivered_price)
    }
  end

  defp format_fixture_prices(
         %{price: %Decimal{} = price, original_price: %Decimal{} = original_price} = fixture
       ) do
    %{
      fixture
      | price: Decimal.to_string(price),
        original_price: Decimal.to_string(original_price)
    }
  end

  defp format_fixture_prices(
         %{price: %Decimal{} = price, delivered_price: %Decimal{} = delivered_price} = fixture
       ) do
    %{
      fixture
      | price: Decimal.to_string(price),
        delivered_price: Decimal.to_string(delivered_price)
    }
  end

  defp format_fixture_prices(%{price: %Decimal{} = price} = fixture) do
    %{
      fixture
      | price: Decimal.to_string(price)
    }
  end

  defp format_fixture_prices(fixture), do: fixture

  defp format_fixture_quantities(
         %{
           quantity: %Decimal{} = quantity,
           original_quantity: %Decimal{} = original_quantity,
           delivered_quantity: %Decimal{} = delivered_quantity
         } = fixture
       ) do
    %{
      fixture
      | quantity: Decimal.to_string(quantity),
        original_quantity: Decimal.to_string(original_quantity),
        delivered_quantity: Decimal.to_string(delivered_quantity)
    }
  end

  defp format_fixture_quantities(
         %{quantity: %Decimal{} = quantity, original_quantity: %Decimal{} = original_quantity} =
           fixture
       ) do
    %{
      fixture
      | quantity: Decimal.to_string(quantity),
        original_quantity: Decimal.to_string(original_quantity)
    }
  end

  defp format_fixture_quantities(
         %{quantity: %Decimal{} = quantity, delivered_quantity: %Decimal{} = delivered_quantity} =
           fixture
       ) do
    %{
      fixture
      | quantity: Decimal.to_string(quantity),
        delivered_quantity: Decimal.to_string(delivered_quantity)
    }
  end

  defp format_fixture_quantities(%{quantity: %Decimal{} = quantity} = fixture) do
    %{
      fixture
      | quantity: Decimal.to_string(quantity)
    }
  end

  defp format_fixture_quantities(fixture), do: fixture
end
