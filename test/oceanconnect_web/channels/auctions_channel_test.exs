defmodule OceanconnectWeb.AuctionsChannelTest do
  use OceanconnectWeb.ChannelCase
  alias Oceanconnect.Utilities
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.AuctionStore.AuctionState

  setup do
    buyer_company = insert(:company)
    insert(:user, company: buyer_company)
    supplier_company = insert(:company, is_supplier: true)
    supplier_1 = insert(:user, company: supplier_company)
    supplier_2 = insert(:user, company: supplier_company)
    non_participant_company = insert(:company)
    non_participant = insert(:user, company: non_participant_company)
    current_time =  DateTime.utc_now()
    auction = insert(:auction, buyer: buyer_company, duration: 1_000, decision_duration: 1_000, auction_start: current_time, suppliers: [supplier_company])
    {:ok, duration} = Time.new(0, 0, round(auction.duration / 1_000), 0)
    {:ok, elapsed_time} = Time.new(0, 0, DateTime.diff(current_time, auction.auction_start), 0)
    time_remaining = Time.diff(duration, elapsed_time) * 1_000
    {:ok, _store} = Auctions.AuctionStore.start_link(auction)

    state = auction
    |> AuctionState.from_auction
    |> Map.put(:status, :open)
    expected_payload = %{
      time_remaining: time_remaining,
      state: state,
      bid_list: []
    }

    {:ok, %{supplier_id: Integer.to_string(supplier_company.id),
            supplier_1: supplier_1,
            supplier_2: supplier_2,
            buyer_id: Integer.to_string(buyer_company.id),
            non_participant_id: Integer.to_string(non_participant_company.id),
            non_participant: non_participant,
            expected_payload: expected_payload,
            auction: auction}}
  end

  describe "Auction Start" do
    test "broadcasts are pushed to the buyer", %{buyer_id: buyer_id,
                                                auction: auction,
                                                expected_payload: expected_payload} do
      channel = "user_auctions:#{buyer_id}"
      event = "auctions_update"

      @endpoint.subscribe(channel)
      Auctions.start_auction(auction)

      assert_rounded_time_broadcast(auction, event, :open, channel, expected_payload)
    end

    test "broadcasts are pushed to the supplier", %{supplier_id: supplier_id,
                                                    auction: auction,
                                                    expected_payload: expected_payload} do
      channel = "user_auctions:#{supplier_id}"
      event = "auctions_update"

      @endpoint.subscribe(channel)
      Auctions.start_auction(auction)

      assert_rounded_time_broadcast(auction, event, :open, channel, expected_payload)
    end

    test "broadcasts are not pushed to a non_participant", %{non_participant_id: non_participant_id,
                                                        auction: auction,
                                                        expected_payload: expected_payload} do
      channel = "user_auctions:#{non_participant_id}"
      event = "auctions_update"

      @endpoint.subscribe(channel)
      Auctions.start_auction(auction)

      refute_broadcast ^event, ^expected_payload
    end

    test "two users from the same company can join their companies channel", %{supplier_id: supplier_company_id, supplier_2: supplier_2} do
      channel = "user_auctions:#{supplier_company_id}"
      user_with_company = Oceanconnect.Accounts.load_company_on_user(supplier_2)

      {:ok, supplier_2_participant_token, _claims} = Oceanconnect.Guardian.encode_and_sign(user_with_company)

      {:ok, supplier_2_socket} = connect(OceanconnectWeb.UserSocket, %{"token" => supplier_2_participant_token})
      assert {:ok, %{}, _socket} = subscribe_and_join(supplier_2_socket, OceanconnectWeb.AuctionsChannel, channel, %{"token" => supplier_2_participant_token})
    end

    test "joining another companies auction channel is unauthorized", %{supplier_id: supplier_id, non_participant: non_participant} do
      channel = "user_auctions:#{supplier_id}"
      user_with_company = Oceanconnect.Accounts.load_company_on_user(non_participant)
      {:ok, non_participant_token, _claims} = Oceanconnect.Guardian.encode_and_sign(user_with_company)

      {:ok, non_participant_socket} = connect(OceanconnectWeb.UserSocket, %{token: non_participant_token})

      assert {:error, %{reason: "unauthorized"}} = subscribe_and_join(non_participant_socket, OceanconnectWeb.AuctionsChannel, channel)
    end

    test "auction start begins time remaining countdown", %{buyer_id: buyer_id,
                                                            auction: auction,
                                                            expected_payload: expected_payload} do
      channel = "user_auctions:#{buyer_id}"
      event = "auctions_update"

      @endpoint.subscribe(channel)
      Auctions.start_auction(auction)

      assert_rounded_time_broadcast(auction, event, :open, channel, expected_payload)
    end
  end

  describe "Auction goes into Decision" do
    setup(%{expected_payload: expected_payload}) do
      payload = expected_payload
      |> Map.put(:time_remaining, 0)
      |> Map.put(:state, Map.put(expected_payload.state, :status, :decision))
      {:ok, %{payload: payload}}
    end

    test "buyers get notified", %{auction: auction, buyer_id: buyer_id, payload: payload} do
      channel = "user_auctions:#{buyer_id}"
      event = "auctions_update"

      @endpoint.subscribe(channel)
      Auctions.start_auction(auction)

      assert_rounded_time_broadcast(auction, event, :decision, channel, payload)
    end

    test "suppliers get notified", %{auction: auction, supplier_id: supplier_id, payload: payload} do
      channel = "user_auctions:#{supplier_id}"
      event = "auctions_update"

      @endpoint.subscribe(channel)
      Auctions.start_auction(auction)

      assert_rounded_time_broadcast(auction, event, :decision, channel, payload)
    end

    test "a non participant is not notified", %{auction: auction, non_participant_id: non_participant_id, payload: payload}  do
      channel = "user_auctions:#{non_participant_id}"
      event = "auctions_update"

      @endpoint.subscribe(channel)
      Auctions.start_auction(auction)

      refute_broadcast ^event, ^payload
    end
  end

  describe "Auction Ends (post Decision Period)" do
    setup(%{expected_payload: expected_payload}) do
      payload = expected_payload
      |> Map.put(:time_remaining, 0)
      |> Map.put(:state, Map.put(expected_payload.state, :status, :closed))
      {:ok, %{payload: payload}}
    end

    test "buyers get notified", %{auction: auction, buyer_id: buyer_id, payload: payload} do
      channel = "user_auctions:#{buyer_id}"
      event = "auctions_update"

      @endpoint.subscribe(channel)
      Auctions.start_auction(auction)

      assert_rounded_time_broadcast(auction, event, :closed, channel, payload)
    end

    test "suppliers get notified", %{auction: auction, supplier_id: supplier_id, payload: payload} do
      channel = "user_auctions:#{supplier_id}"
      event = "auctions_update"

      @endpoint.subscribe(channel)
      Auctions.start_auction(auction)

      assert_rounded_time_broadcast(auction, event, :closed, channel, payload)
    end

    test "a non participant is not notified", %{auction: auction, non_participant_id: non_participant_id, payload: payload}  do
      channel = "user_auctions:#{non_participant_id}"
      event = "auctions_update"

      @endpoint.subscribe(channel)
      Auctions.start_auction(auction)

      refute_broadcast ^event, ^payload
    end
  end

  describe "Placing Bids" do
    setup %{auction: auction} do
      Auctions.start_auction(auction)
      :ok
    end

    test "buyers get notified", %{auction: auction = %{id: auction_id}, buyer_id: buyer_id, supplier_id: supplier_id} do
      channel = "user_auctions:#{buyer_id}"
      event = "auctions_update"

      @endpoint.subscribe(channel)
      Auctions.place_bid(auction, %{"amount" => 1.25}, supplier_id)

      buyer_payload = auction
      |> Auctions.AuctionPayload.get_auction_payload!(String.to_integer(buyer_id))

      receive do
        %Phoenix.Socket.Broadcast{} -> nil
      after
        5000 ->
          assert false, "Expected message received nothing."
      end

      receive do
        %Phoenix.Socket.Broadcast{
          event: ^event,
          payload: %{auction: %{id: ^auction_id}, state: %{winning_bids: winning_bids}, bid_list: bid_list},
          topic: ^channel} ->
            assert buyer_payload.bid_list == bid_list
            assert buyer_payload.state.winning_bids == winning_bids
      after
        5000 ->
          assert false, "Expected message received nothing."
      end

      {:ok, auction_store_pid} = Oceanconnect.Auctions.AuctionStore.find_pid(auction_id)
      GenServer.cast(auction_store_pid, {:end_auction, auction})

      decision_buyer_payload = auction
      |> Auctions.AuctionPayload.get_auction_payload!(String.to_integer(buyer_id))

      receive do
        %Phoenix.Socket.Broadcast{
          event: ^event,
          payload: %{auction: %{id: ^auction_id}, state: %{status: :decision, winning_bids: winning_bids}, bid_list: bid_list},
          topic: ^channel} ->
            assert decision_buyer_payload.bid_list == bid_list
            assert decision_buyer_payload.state.winning_bids == winning_bids
      after
        5000 ->
          assert false, "Expected message received nothing."
      end
    end

    test "suppliers get notified", %{auction: auction = %{id: auction_id}, supplier_id: supplier_id} do
      channel = "user_auctions:#{supplier_id}"
      event = "auctions_update"

      @endpoint.subscribe(channel)
      Auctions.place_bid(auction, %{"amount" => 1.25}, String.to_integer(supplier_id))

      supplier_payload = auction
      |> Auctions.AuctionPayload.get_auction_payload!(String.to_integer(supplier_id))

      receive do
        %Phoenix.Socket.Broadcast{} -> nil
      after
        5000 ->
          assert false, "Expected message received nothing."
      end

      receive do
        %Phoenix.Socket.Broadcast{
          event: ^event,
          payload: %{
            auction: %{id: ^auction_id},
            state: %{winning_bids: winning_bids, winning_bids_position: position},
            bid_list: bid_list
          },
          topic: ^channel} ->
            assert supplier_payload.bid_list == bid_list
            assert supplier_payload.state.winning_bids == winning_bids
            assert supplier_payload.state.winning_bids_position == position
      after
        5000 ->
          assert false, "Expected message received nothing."
      end

      {:ok, auction_store_pid} = Oceanconnect.Auctions.AuctionStore.find_pid(auction_id)
      GenServer.cast(auction_store_pid, {:end_auction, auction})

      decision_supplier_payload = auction
      |> Auctions.AuctionPayload.get_auction_payload!(String.to_integer(supplier_id))

      receive do
        %Phoenix.Socket.Broadcast{
          event: ^event,
          payload: %{
            auction: %{id: ^auction_id},
            state: %{winning_bids: winning_bids, winning_bids_position: position},
            bid_list: bid_list
          },
          topic: ^channel} ->
            assert decision_supplier_payload.bid_list == bid_list
            assert decision_supplier_payload.state.winning_bids == winning_bids
            assert supplier_payload.state.winning_bids_position == position
      after
        5000 ->
          assert false, "Expected message received nothing."
      end
    end

    test "a non participant is not notified", %{non_participant_id: non_participant_id}  do
      channel = "user_auctions:#{non_participant_id}"
      event = "auctions_update"

      @endpoint.subscribe(channel)

      refute_broadcast ^event, %{}
    end
  end
end
