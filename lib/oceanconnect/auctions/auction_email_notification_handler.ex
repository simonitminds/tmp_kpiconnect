defmodule Oceanconnect.Auctions.AuctionEmailNotificationHandler do
  use GenServer
  alias Oceanconnect.Auctions

  alias Oceanconnect.Auctions.{
    Auction,
    AuctionEvent,
    AuctionEmailNotifier,
    AuctionStore.AuctionState,
    Solution
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
          type: :winning_solution_selected,
          data: %{
            solution: %Solution{
              bids: winning_solution_bids
            },
            state: %AuctionState{
              submitted_barges: submitted_barges
            }
          }
        },
        state
      ) do
    active_participants = Auctions.active_participants(auction_id)
    AuctionEmailNotifier.notify_auction_completed(
      winning_solution_bids,
      submitted_barges,
      auction_id,
      active_participants
    )

    {:noreply, state}
  end

  def handle_info(
        %AuctionEvent{type: :auction_created, data: auction = %Auction{}},
        state
      ) do
    AuctionEmailNotifier.notify_auction_created(auction)
    {:noreply, state}
  end

  def handle_info(
        %AuctionEvent{type: :upcoming_auction_notified, data: auction = %Auction{}},
        state
      ) do
    AuctionEmailNotifier.notify_upcoming_auction(auction)
    {:noreply, state}
  end

  def handle_info(
        %AuctionEvent{type: :auction_canceled, data: %{auction: auction = %Auction{}}},
        state
      ) do
    auction
    |> Auctions.fully_loaded()
    |> AuctionEmailNotifier.notify_auction_canceled()

    {:noreply, state}
  end

  def handle_info(_event, state) do
    {:noreply, state}
  end

  defp get_event_handler_name(auction_id) do
    {:via, Registry, {@registry_name, auction_id}}
  end
end
