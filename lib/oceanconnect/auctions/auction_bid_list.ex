defmodule Oceanconnect.Auctions.AuctionBidList do
  use GenServer
  alias Oceanconnect.Auctions.{Auction, AuctionNotifier}
  alias __MODULE__.{AuctionBid, BidCommand}

  @registry_name :auction_bids_registry

  defmodule AuctionBid do
    defstruct id: nil,
      auction_id: nil,
      amount: nil,
      credit_terms: nil,
      fuel_id: nil,
      fuel_quantity: nil,
      expiration: nil,
      min_amount: nil,
      supplier_id: nil,
      additional_charges: false,
      barging: nil,
      wharfage: nil,
      booming: nil,
      taxes: nil,
      other: nil,
      total_price: nil,
      time_entered: nil
  end

  defmodule BidCommand do
    defstruct command: :enter_bid, data: nil

    def enter_bid(bid = %AuctionBid{amount: amount, fuel_quantity: fuel_quantity}) do
      time_entered = DateTime.utc_now()
      total_price = amount * fuel_quantity
      updated_bid = Map.merge(bid, %{id: UUID.uuid4(:hex), total_price: total_price, time_entered: time_entered})
      %BidCommand{command: :enter_bid, data: updated_bid}
    end
  end

  def find_pid(auction_id) do
    with [{pid, _}] <- Registry.lookup(@registry_name, auction_id) do
      {:ok, pid}
    else
      [] -> {:error, "Auction Bid List Not Started"}
    end
  end

  defp get_auction_bid_list_name(auction_id) do
    {:via, Registry, {@registry_name, auction_id}}
  end

  def start_link(auction_id) do
    GenServer.start_link(__MODULE__, [], name: get_auction_bid_list_name(auction_id))
  end

  def init([]) do
    {:ok, []}
  end

   # Client
  def get_bid_list(auction_id) do
    with {:ok, pid} <- find_pid(auction_id),
    do: GenServer.call(pid, :get_bid_list)
  end

  def process_command(%BidCommand{command: :enter_bid, data: bid = %AuctionBid{auction_id: auction_id}}) do
    with {:ok, pid} <- find_pid(auction_id),
    do: GenServer.cast(pid, {:enter_bid, bid})
  end

  def process_command(%BidCommand{command: cmd, data: bid = %AuctionBid{auction_id: auction_id}}) do
    with {:ok, pid} <- find_pid(auction_id),
    do: GenServer.call(pid, {cmd, bid})
  end

   # Server
  def handle_call(:get_bid_list, _from, current_state) do
    {:reply, current_state, current_state}
  end

  def handle_cast({:enter_bid, bid = %AuctionBid{}}, current_state) do
    new_state = [bid | current_state]
    # AuctionNotifier.notify_participants(new_state)
    {:noreply, new_state}
  end
end
