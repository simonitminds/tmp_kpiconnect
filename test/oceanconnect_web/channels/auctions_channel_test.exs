defmodule OceanconnectWeb.AuctionsChannelTest do
  use OceanconnectWeb.ChannelCase, async: false
  alias Oceanconnect.Utilities
  alias Oceanconnect.{Auctions}

  setup do
    buyer_company = insert(:company)
    insert(:user, company: buyer_company)
    supplier_company = insert(:company, is_supplier: true)
    insert(:user, company: supplier_company)
    non_participant_company = insert(:company)
    non_participant = insert(:user, company: non_participant_company)
    current_time =  DateTime.utc_now()
    auction = insert(:auction, buyer: buyer_company, duration: 1_000, decision_duration: 1_000, auction_start: current_time, suppliers: [supplier_company])
    {:ok, duration} = Time.new(0, 0, round(auction.duration / 1_000), 0)
    {:ok, elapsed_time} = Time.new(0, 0, DateTime.diff(current_time, auction.auction_start), 0)
    time_remaining = Time.diff(duration, elapsed_time) * 1_000
    {:ok, _store} = Auctions.AuctionStore.start_link(auction)

    expected_payload = %{id: auction.id, state: %{status: :open, time_remaining: time_remaining, current_server_time: current_time}}

    {:ok, %{supplier_id: Integer.to_string(supplier_company.id),
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

    test "joining another users auction channel is unauthorized", %{supplier_id: supplier_id, non_participant: non_participant} do
      channel = "user_auctions:#{supplier_id}"
      non_participant_token = OceanconnectWeb.Plugs.Auth.generate_user_token(build_conn(), non_participant)
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
      current_time =  DateTime.utc_now()
      payload = put_in(expected_payload, [:state], %{status: :decision, time_remaining: 0, current_server_time: current_time})
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
      current_time =  DateTime.utc_now()
      payload = put_in(expected_payload, [:state], %{status: :closed, time_remaining: 0, current_server_time: current_time})
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
end
