defmodule Oceanconnect.Auctions.AuctionBidList do
  use GenServer
  alias Oceanconnect.Auctions.Command
  alias __MODULE__.AuctionBid

  @registry_name :auction_bids_registry

  defmodule AuctionBid do
    @enforce_keys [:auction_id, :amount, :supplier_id]
    defstruct id: nil,
              auction_id: nil,
              amount: nil,
              credit_terms: nil,
              fuel_id: nil,
              fuel_quantity: nil,
              expiration: nil,
              min_amount: nil,
              supplier_id: nil,
              total_price: nil,
              time_entered: nil

    def from_params_to_auction_bid(
          %{
            "amount" => amount,
            "min_amount" => min_amount,
            "supplier_id" => supplier_id,
            "time_entered" => time_entered
          },
          auction = %Oceanconnect.Auctions.Auction{}
        ) do
      params = %{
        id: UUID.uuid4(:hex),
        auction_id: auction.id,
        amount: amount,
        fuel_id: auction.fuel_id,
        fuel_quantity: auction.fuel_quantity,
        min_amount: min_amount,
        supplier_id: supplier_id,
        time_entered: time_entered
      }

      Map.merge(%AuctionBid{auction_id: nil, amount: nil, supplier_id: nil}, params)
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

  def get_bid(auction_id, bid_id) do
    with {:ok, pid} <- find_pid(auction_id),
         do: GenServer.call(pid, {:get_bid, bid_id})
  end

  def process_command(%Command{
        command: :enter_bid,
        data: bid = %AuctionBid{auction_id: auction_id}
      }) do
    with {:ok, pid} <- find_pid(auction_id),
         do: GenServer.call(pid, {:enter_bid, bid})
  end

  def process_command(%Command{command: cmd, data: bid = %AuctionBid{auction_id: auction_id}}) do
    with {:ok, pid} <- find_pid(auction_id),
         do: GenServer.call(pid, {cmd, bid})
  end

  # Server
  def handle_call(:get_bid_list, _from, current_state) do
    {:reply, current_state, current_state}
  end

  def handle_call({:get_bid, bid_id}, _from, current_state) do
    bid =
      current_state
      |> Enum.filter(fn bid -> bid.id == bid_id end)
      |> List.first()

    {:reply, bid, current_state}
  end

  def handle_call({:enter_bid, bid = %AuctionBid{supplier_id: supplier_id}}, _from, current_state) do
    supplier_first_bid =
      current_state
      |> Enum.map(fn bid -> bid.supplier_id end)
      |> Enum.member?(supplier_id)

    new_state = [bid | current_state]
    {:reply, not supplier_first_bid, new_state}
  end
end
