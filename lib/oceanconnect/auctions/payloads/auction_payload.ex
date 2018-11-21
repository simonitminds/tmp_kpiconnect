defmodule Oceanconnect.Auctions.AuctionPayload do
  alias __MODULE__
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{Auction, AuctionTimer}
  alias Oceanconnect.Auctions.AuctionStore.AuctionState
  alias Oceanconnect.Auctions.Payloads.{BargesPayload, ProductBidsPayload, SolutionsPayload}

  defstruct time_remaining: nil,
            current_server_time: nil,
            auction: nil,
            status: :pending,
            participations: %{},
            bid_history: [],
            product_bids: %{},
            solutions: %{},
            submitted_barges: []

  def get_auction_payload!(auction = %Auction{buyer_id: buyer_id}, buyer_id) do
    # auction = Auctions.fully_loaded(auction)
    auction_state = Auctions.get_auction_state!(auction)
    get_buyer_auction_payload(auction, buyer_id, auction_state)
  end

  def get_auction_payload!(auction = %Auction{}, supplier_id) do
    # auction = Auctions.fully_loaded(auction)
    auction_state = Auctions.get_auction_state!(auction)
    get_supplier_auction_payload(auction, supplier_id, auction_state)
  end

  def get_auction_payload!(
        auction = %Auction{buyer_id: buyer_id},
        buyer_id,
        auction_state = %AuctionState{}
      ) do
    # auction = Auctions.fully_loaded(auction)
    get_buyer_auction_payload(auction, buyer_id, auction_state)
  end

  def get_auction_payload!(auction = %Auction{}, supplier_id, auction_state = %AuctionState{}) do
    # auction = Auctions.fully_loaded(auction)
    get_supplier_auction_payload(auction, supplier_id, auction_state)
  end

  def get_bid_history(supplier_id, %AuctionState{product_bids: product_bids}) do
    Enum.map(product_bids, fn {_fuel_id, product_state} ->
      Enum.filter(product_state.bids, fn bid -> bid.supplier_id == supplier_id end)
    end)
    |> List.flatten()
    |> Enum.sort_by(& DateTime.to_unix(&1.time_entered, :microsecond))
    |> Enum.reverse()
  end

  def get_supplier_auction_payload(
        auction = %Auction{},
        supplier_id,
        state = %AuctionState{
          product_bids: product_bids,
          status: status,
        }
      ) do
    %AuctionPayload{
      time_remaining: get_time_remaining(auction, state),
      current_server_time: DateTime.utc_now(),
      auction: scrub_auction(auction, supplier_id),
      participations: %{supplier_id => Enum.find(auction.auction_suppliers, fn(supplier) -> supplier.supplier_id == supplier_id end).participation},
      status: status,
      solutions:
        SolutionsPayload.get_solutions_payload!(state, auction: auction, supplier: supplier_id),
      bid_history: get_bid_history(supplier_id, state),
      product_bids:
        Enum.reduce(product_bids, %{}, fn {fuel_id, product_state}, acc ->
          Map.put(
            acc,
            fuel_id,
            ProductBidsPayload.get_product_bids_payload!(product_state,
              auction: auction,
              supplier: supplier_id
            )
          )
        end),
      submitted_barges:
        BargesPayload.get_barges_payload!(state.submitted_barges, supplier: supplier_id)
    }
  end

  def get_buyer_auction_payload(
        auction = %Auction{anonymous_bidding: anonymous_bidding},
        buyer_id,
        state = %AuctionState{
          product_bids: product_bids,
          status: status,
        }
      ) do
    %AuctionPayload{
      time_remaining: get_time_remaining(auction, state),
      current_server_time: DateTime.utc_now(),
      auction: scrub_auction(auction, buyer_id),
      status: status,
      solutions:
        SolutionsPayload.get_solutions_payload!(state, auction: auction, buyer: buyer_id),
      bid_history: [],
      participations: get_participations(anonymous_bidding),
      product_bids:
        Enum.reduce(product_bids, %{}, fn {fuel_id, product_state}, acc ->
          Map.put(
            acc,
            fuel_id,
            ProductBidsPayload.get_product_bids_payload!(product_state,
              auction: auction,
              buyer: buyer_id
            )
          )
        end),
      submitted_barges: BargesPayload.get_barges_payload!(state.submitted_barges, buyer: buyer_id)
    }
  end

  defp get_participations(%Auction{anonymous_bidding:  true}), do: %{}
  defp get_participations(%Auction{auction_suppliers:  auction_suppliers}) do
    auction_suppliers
    |> Enum.reduce(%{}, fn(auction_supplier, acc) -> Map.put(acc, auction_supplier.supplier_id, auction_supplier.participation) end)
  end

  defp get_time_remaining(auction = %Auction{}, %AuctionState{status: :open}) do
    AuctionTimer.read_timer(auction.id, :duration)
  end

  defp get_time_remaining(auction = %Auction{}, %AuctionState{status: :decision}) do
    AuctionTimer.read_timer(auction.id, :decision_duration)
  end

  defp get_time_remaining(_auction = %Auction{}, %AuctionState{}), do: 0

  defp scrub_auction(auction = %Auction{buyer_id: buyer_id}, buyer_id), do: auction

  defp scrub_auction(auction = %Auction{}, _supplier_id) do
    Map.delete(auction, :suppliers)
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
        submitted_barges: submitted_barges
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
      submitted_barges: submitted_barges
    }
  end
end
