defmodule Oceanconnect.Auctions.AuctionNotifier do
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{Auction, AuctionPayload, AuctionStore.AuctionState}

  @task_supervisor Application.get_env(:oceanconnect, :task_supervisor) || Task.Supervisor

  def notify_participants(auction_state = %AuctionState{auction_id: auction_id}) do
    auction = Auctions.AuctionCache.read(auction_id)
    participants = Auctions.auction_participant_ids(auction)

    Enum.map(participants, fn user_id ->
      payload =
        auction
        |> AuctionPayload.get_auction_payload!(user_id, auction_state)

      send_notification_to_participants("user_auctions", payload, [user_id])
    end)
  end

  def notify_participants(auction = %Auction{}) do
    participants = Auctions.auction_participant_ids(auction)

    Enum.map(participants, fn user_id ->
      payload =
        auction
        |> AuctionPayload.get_auction_payload!(user_id)

      send_notification_to_participants("user_auctions", payload, [user_id])
    end)
  end

  def notify_auction_created(auction = %Auction{id: auction_id}) do
    auction = auction |> Auctions.fully_loaded()
    invitation_emails = OceanconnectWeb.Email.auction_invitation(auction)
    invitation_emails = deliver_emails(invitation_emails)
    {:ok, invitation_emails}
  end

  def notify_upcoming_auction(auction = %Auction{}) do
    %{supplier_emails: supplier_emails, buyer_emails: buyer_emails} =
      OceanconnectWeb.Email.auction_starting_soon(auction)

    upcoming_emails = List.flatten([supplier_emails | buyer_emails])
    deliver_emails(upcoming_emails)
    {:ok, upcoming_emails}
  end

  def notify_auction_canceled(auction = %Auction{}) do
    %{supplier_emails: supplier_emails, buyer_emails: buyer_emails} =
      OceanconnectWeb.Email.auction_canceled(auction)

    cancellation_emails = List.flatten([supplier_emails | buyer_emails])
    deliver_emails(cancellation_emails)
    {:ok, cancellation_emails}
  end

  def notify_auction_completed(bid_amount, total_price, supplier_id, auction_id) do
    auction = Auctions.get_auction!(auction_id) |> Auctions.fully_loaded()
    winning_supplier_company = Oceanconnect.Accounts.get_company!(supplier_id)

    %{supplier_emails: supplier_emails, buyer_emails: buyer_emails} =
      OceanconnectWeb.Email.auction_closed(
        bid_amount,
        total_price,
        winning_supplier_company,
        auction
      )

    completion_emails = List.flatten([supplier_emails | buyer_emails])
    deliver_emails(completion_emails)
    {:ok, completion_emails}
  end

  defp deliver_emails(emails) do
    {:ok, pid} = Task.Supervisor.start_link()

    @task_supervisor.async_nolink(pid, fn ->
      Enum.map(emails, fn email ->
        OceanconnectWeb.Mailer.deliver_now(email)
      end)
    end)
  end

  def send_notification_to_participants(channel, payload, participants) do
    {:ok, pid} = Task.Supervisor.start_link()

    @task_supervisor.async_nolink(pid, fn ->
      Enum.map(participants, fn id ->
        OceanconnectWeb.Endpoint.broadcast("#{channel}:#{id}", "auctions_update", payload)
      end)
    end)
  end

  def notify_updated_bid(auction, _bid, _supplier_id) do
    buyer_payload =
      auction
      |> AuctionPayload.get_auction_payload!(auction.buyer_id)

    send_notification_to_participants("user_auctions", buyer_payload, [auction.buyer_id])

    Enum.map(Auctions.auction_supplier_ids(auction), fn supplier_id ->
      supplier_payload =
        auction
        |> AuctionPayload.get_auction_payload!(supplier_id)

      send_notification_to_participants("user_auctions", supplier_payload, [supplier_id])
    end)
  end
end
