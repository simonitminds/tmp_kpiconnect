defmodule OceanconnectWeb.AuctionsChannelTest do
  use OceanconnectWeb.ChannelCase
  alias Oceanconnect.Utilities
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{AuctionStore.AuctionState, AuctionSupervisor}

  setup do
    buyer_company = insert(:company)
    insert(:user, company: buyer_company)
    supplier_company = insert(:company, is_supplier: true)
    supplier3_company = insert(:company, is_supplier: true)
    supplier_1 = insert(:user, company: supplier_company)
    supplier_2 = insert(:user, company: supplier_company)
    non_participant_company = insert(:company)
    non_participant = insert(:user, company: non_participant_company)
    auction = insert(:auction,
      buyer: buyer_company, duration: 1_000, decision_duration: 1_000,
      suppliers: [supplier_company, supplier3_company]
    )
    {:ok, _pid} = start_supervised({AuctionSupervisor, auction})

    state = AuctionState.from_auction(auction.id)
    |> Map.put(:status, :open)
    expected_payload = %{
      time_remaining: auction.duration,
      state: state,
      bid_list: []
    }

    {:ok, %{supplier_id: supplier_company.id,
            supplier_1: supplier_1,
            supplier_2: supplier_2,
            supplier3: supplier3_company,
            buyer_id: buyer_company.id,
            non_participant_id: non_participant_company.id,
            non_participant: non_participant,
            expected_payload: expected_payload,
            auction: auction}}
  end

  describe "auction start" do
    test "broadcasts are pushed to the buyer", %{buyer_id: buyer_id,
                                                auction: auction,
                                                expected_payload: expected_payload} do
      channel = "user_auctions:#{Integer.to_string(buyer_id)}"
      event = "auctions_update"

      @endpoint.subscribe(channel)
      Auctions.start_auction(auction)

      auction_id = auction.id
      receive do
        %Phoenix.Socket.Broadcast{
          event: ^event,
          payload: payload = %{auction: %{id: ^auction_id}, state: %{status: :open}},
          topic: ^channel} ->
            assert Utilities.round_time_remaining(payload.time_remaining) ==
                    Utilities.round_time_remaining(expected_payload.time_remaining)
      after
        5000 ->
          assert false, "Expected message received nothing."
      end
    end

    test "broadcasts are pushed to the supplier", %{supplier_id: supplier_id,
                                                    auction: auction,
                                                    expected_payload: expected_payload} do
      channel = "user_auctions:#{Integer.to_string(supplier_id)}"
      event = "auctions_update"

      @endpoint.subscribe(channel)
      Auctions.start_auction(auction)

      auction_id = auction.id
      receive do
        %Phoenix.Socket.Broadcast{
          event: ^event,
          payload: payload = %{auction: %{id: ^auction_id}, state: %{status: :open}},
          topic: ^channel} ->
            assert Utilities.round_time_remaining(payload.time_remaining) ==
                    Utilities.round_time_remaining(expected_payload.time_remaining)
      after
        5000 ->
          assert false, "Expected message received nothing."
      end
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
      channel = "user_auctions:#{Integer.to_string(supplier_id)}"
      user_with_company = Oceanconnect.Accounts.load_company_on_user(non_participant)
      {:ok, non_participant_token, _claims} = Oceanconnect.Guardian.encode_and_sign(user_with_company)

      {:ok, non_participant_socket} = connect(OceanconnectWeb.UserSocket, %{token: non_participant_token})

      assert {:error, %{reason: "unauthorized"}} = subscribe_and_join(non_participant_socket, OceanconnectWeb.AuctionsChannel, channel)
    end
  end

  describe "auction goes into decision" do
    setup(%{auction: auction, expected_payload: expected_payload}) do
      payload = expected_payload
      |> Map.put(:time_remaining, auction.decision_duration)
      |> Map.put(:state, Map.put(expected_payload.state, :status, :decision))
      Auctions.start_auction(auction)
      {:ok, %{expected_payload: payload}}
    end

    test "buyers get notified with timer timeout", %{auction: auction, buyer_id: buyer_id, expected_payload: expected_payload} do
      channel = "user_auctions:#{Integer.to_string(buyer_id)}"
      event = "auctions_update"

      @endpoint.subscribe(channel)

      auction_id = auction.id
      receive do
        %Phoenix.Socket.Broadcast{
          event: ^event,
          payload: payload = %{auction: %{id: ^auction_id}, state: %{status: :decision}},
          topic: ^channel} ->
            assert Utilities.round_time_remaining(payload.time_remaining) ==
                    Utilities.round_time_remaining(expected_payload.time_remaining)
      after
        5000 ->
          assert false, "Expected message received nothing."
      end
    end

    test "suppliers get notified", %{auction: auction, supplier_id: supplier_id, expected_payload: expected_payload} do
      channel = "user_auctions:#{Integer.to_string(supplier_id)}"
      event = "auctions_update"

      @endpoint.subscribe(channel)
      Auctions.end_auction(auction)

      auction_id = auction.id
      receive do
        %Phoenix.Socket.Broadcast{
          event: ^event,
          payload: payload = %{auction: %{id: ^auction_id}, state: %{status: :decision}},
          topic: ^channel} ->
            assert Utilities.round_time_remaining(payload.time_remaining) ==
                    Utilities.round_time_remaining(expected_payload.time_remaining)
      after
        5000 ->
          assert false, "Expected message received nothing."
      end
    end

    test "a non participant is not notified", %{auction: auction, non_participant_id: non_participant_id, expected_payload: expected_payload}  do
      channel = "user_auctions:#{non_participant_id}"
      event = "auctions_update"

      @endpoint.subscribe(channel)
      Auctions.end_auction(auction)

      refute_broadcast ^event, ^expected_payload
    end
  end

  describe "auction expires (decision period runs out with no selection)" do
    setup(%{auction: auction, expected_payload: expected_payload}) do
      payload = expected_payload
      |> Map.put(:time_remaining, 0)
      |> Map.put(:state, Map.put(expected_payload.state, :status, :expired))
      auction
      |> Auctions.start_auction
      |> Auctions.end_auction
      {:ok, %{expected_payload: payload}}
    end

    test "buyers get notified with timer timeout", %{auction: auction, buyer_id: buyer_id, expected_payload: expected_payload} do
      channel = "user_auctions:#{Integer.to_string(buyer_id)}"
      event = "auctions_update"

      @endpoint.subscribe(channel)

      auction_id = auction.id
      receive do
        %Phoenix.Socket.Broadcast{
          event: ^event,
          payload: payload = %{auction: %{id: ^auction_id}, state: %{status: :expired}},
          topic: ^channel} ->
            assert Utilities.round_time_remaining(payload.time_remaining) ==
                    Utilities.round_time_remaining(expected_payload.time_remaining)
      after
        5000 ->
          assert false, "Expected message received nothing."
      end
    end

    test "suppliers get notified", %{auction: auction, supplier_id: supplier_id, expected_payload: expected_payload} do
      channel = "user_auctions:#{Integer.to_string(supplier_id)}"
      event = "auctions_update"

      @endpoint.subscribe(channel)
      Auctions.expire_auction(auction)

      auction_id = auction.id
      receive do
        %Phoenix.Socket.Broadcast{
          event: ^event,
          payload: payload = %{auction: %{id: ^auction_id}, state: %{status: :expired}},
          topic: ^channel} ->
            assert Utilities.round_time_remaining(payload.time_remaining) ==
                    Utilities.round_time_remaining(expected_payload.time_remaining)
      after
        5000 ->
          assert false, "Expected message received nothing."
      end
    end

    test "a non participant is not notified", %{auction: auction, non_participant_id: non_participant_id, expected_payload: expected_payload}  do
      channel = "user_auctions:#{non_participant_id}"
      event = "auctions_update"

      @endpoint.subscribe(channel)
      Auctions.expire_auction(auction)

      refute_broadcast ^event, ^expected_payload
    end
  end

  describe "placing bids" do
    setup %{auction: auction} do
      Auctions.start_auction(auction)
      :ok
    end

    test "buyers get notified", %{auction: auction = %{id: auction_id}, buyer_id: buyer_id, supplier_id: supplier_id} do
      channel = "user_auctions:#{Integer.to_string(buyer_id)}"
      event = "auctions_update"

      @endpoint.subscribe(channel)

      Auctions.place_bid(auction, %{"amount" => 1.25}, supplier_id)

      buyer_payload = auction
      |> Auctions.AuctionPayload.get_auction_payload!(buyer_id)

      receive do
        %Phoenix.Socket.Broadcast{
          event: ^event,
          payload: %{auction: %{id: ^auction_id}, state: %{status: :open, lowest_bids: lowest_bids}, bid_list: bid_list},
          topic: ^channel} ->
            assert buyer_payload.bid_list == bid_list
            assert buyer_payload.state.lowest_bids == lowest_bids
      after
        5000 ->
          assert false, "Expected message received nothing."
      end

      Auctions.end_auction(auction)

      decision_buyer_payload = auction
      |> Auctions.AuctionPayload.get_auction_payload!(buyer_id)

      receive do
        %Phoenix.Socket.Broadcast{
          event: ^event,
          payload: %{auction: %{id: ^auction_id}, state: %{status: :decision, lowest_bids: lowest_bids}, bid_list: bid_list},
          topic: ^channel} ->
            assert decision_buyer_payload.bid_list == bid_list
            assert decision_buyer_payload.state.lowest_bids == lowest_bids
      after
        5000 ->
          assert false, "Expected message received nothing."
      end
    end

    test "suppliers get notified", %{auction: auction = %{id: auction_id}, supplier_id: supplier_id, supplier3: supplier3} do
      channel = "user_auctions:#{Integer.to_string(supplier_id)}"
      event = "auctions_update"

      @endpoint.subscribe(channel)

      Auctions.place_bid(auction, %{"amount" => 1.25}, supplier_id)
      supplier_payload = auction
      |> Auctions.AuctionPayload.get_auction_payload!(supplier_id)

      receive do
        %Phoenix.Socket.Broadcast{
          event: ^event,
          payload: %{
            auction: auction = %{id: ^auction_id},
            state: state = %{status: :open, lowest_bids: lowest_bids, lowest_bids_position: position, multiple: multiple},
            bid_list: bid_list,
            time_remaining: time_remaining
          },
          topic: ^channel} ->
            assert supplier_payload.bid_list == bid_list
            assert supplier_payload.state.lowest_bids == lowest_bids
            assert supplier_payload.state.lowest_bids_position == position
            assert supplier_payload.state.multiple == multiple
            refute lowest_bids |> hd |> Map.has_key?(:supplier_id)
            refute state |> Map.has_key?(:supplier_ids)
            refute auction |> Map.has_key?(:suppliers)
            assert time_remaining > 3 * 60_000 - 1_000 #Auction extended
      after
        5000 ->
          assert false, "Expected message received nothing."
      end

      Auctions.place_bid(auction, %{"amount" => 1.25}, supplier3.id)
      receive do
        %Phoenix.Socket.Broadcast{} -> nil
      after
        5000 ->
          assert false, "Expected message received nothing."
      end

      Auctions.end_auction(auction)

      decision_supplier_payload = auction
      |> Auctions.AuctionPayload.get_auction_payload!(supplier_id)

      receive do
        %Phoenix.Socket.Broadcast{
          event: ^event,
          payload: %{
            auction: auction = %{id: ^auction_id},
            state: state = %{status: :decision, lowest_bids: lowest_bids, lowest_bids_position: position, multiple: multiple},
            bid_list: bid_list,
            time_remaining: time_remaining
          },
          topic: ^channel} ->
            assert decision_supplier_payload.bid_list == bid_list
            assert decision_supplier_payload.state.lowest_bids == lowest_bids
            assert decision_supplier_payload.state.lowest_bids_position == position
            assert decision_supplier_payload.state.multiple == multiple
            refute lowest_bids |> hd |> Map.has_key?(:supplier_id)
            refute state |> Map.has_key?(:supplier_ids)
            refute auction |> Map.has_key?(:suppliers)
            assert time_remaining > auction.decision_duration - 1_000
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
