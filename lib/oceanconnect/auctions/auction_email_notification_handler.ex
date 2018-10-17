defmodule Oceanconnect.Auctions.AuctionEmailNotificationHandler do
  use GenServer
  alias Oceanconnect.Auctions

  alias Oceanconnect.Auctions.{
    Auction,
    AuctionEvent,
    AuctionBid,
    AuctionNotifier,
    AuctionStore.AuctionState
  }

  @registry_name :auction_email_notification_handler_registry

  # Client
  def start_link(auction_id) do
    GenServer.start_link(__MODULE__, auction_id, name: get_event_handler_name(auction_id))
  end

  def find_pid(auction_id) do
    with [{pid, _}] <- Registry.lookup(@registry_name, auction_id) do
      {:ok, pid}
    else
      [] -> {:error, "Auction Store Not Started"}
    end
  end

  # Server

  def init(auction_id) do
    Phoenix.PubSub.subscribe(:auction_pubsub, "auction:#{auction_id}")
    {:ok, auction_id}
  end

  def handle_info(
    %AuctionEvent{
      auction_id: auction_id,
      type: :winning_bid_selected,
      data: %{
        bid: %AuctionBid{
          amount: bid_amount,
          supplier_id: supplier_id,
          is_traded_bid: is_traded_bid
        }
      }
    },
    state
  ) do
    AuctionNotifier.notify_auction_completed(bid_amount, supplier_id, auction_id, is_traded_bid)
    {:noreply, state}
  end

  def handle_info(
    %AuctionEvent{type: :auction_created, data: auction = %Auction{}},
    state = %AuctionState{status: :pending}
  ) do
    AuctionNotifier.notify_auction_created(auction)
    {:noreply, state}
  end

  def handle_info(
    %AuctionEvent{type: :upcoming_auction_notified, data: auction = %Auction{}},
    state
  ) do
    AuctionNotifier.notify_upcoming_auction(auction)
    {:noreply, state}
  end

  def handle_info(
    %AuctionEvent{auction_id: auction_id, type: :auction_canceled, data: %AuctionState{}},
    state
  ) do
    auction_id
    |> Auctions.get_auction!()
    |> Auctions.fully_loaded()
    |> AuctionNotifier.notify_auction_canceled()

    {:noreply, state}
  end

  def handle_info(_event, state) do
    {:noreply, state}
  end

  defp get_event_handler_name(auction_id) do
    {:via, Registry, {@registry_name, auction_id}}
  end
end
