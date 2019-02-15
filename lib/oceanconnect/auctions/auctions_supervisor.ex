defmodule Oceanconnect.Auctions.AuctionsSupervisor do
  # Automatically defines child_spec/1
  use DynamicSupervisor
  require Logger
  import Oceanconnect.Auctions.Guards

  def start_link() do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_child(auction = %struct{}) when is_auction(struct) do
    with {:ok, core_services_pid} <-
           DynamicSupervisor.start_child(
             __MODULE__,
             {Oceanconnect.Auctions.AuctionSupervisor, {auction, %{exclude_children: []}}}
           ),
         {:ok, email_servies_pid} <-
           DynamicSupervisor.start_child(
             __MODULE__,
             {Oceanconnect.Auctions.AuctionEmailSupervisor, {auction, %{exclude_children: []}}}
           ) do
      {:ok, {core_services_pid, email_servies_pid}}
    else
      {:error, {:already_started, pid}} ->
        {:error, {:already_started, pid}}

      error ->
        Logger.error(inspect(error))
        raise("Could Not Start AuctionStore for auction #{auction.id}")
    end
  end

  def stop_child(_auction = %struct{id: auction_id}) when is_auction(struct) do
    with {:ok, pid} <- Oceanconnect.Auctions.AuctionSupervisor.find_pid(auction_id),
         :ok <- DynamicSupervisor.terminate_child(__MODULE__, pid) do
      Logger.info("Auction ID: #{auction_id} Services Stopped")
      {:ok, "Auction ID: #{auction_id} Services Stopped"}
    else
      {:error, msg} -> {:error, msg}
    end
  end
end
