defmodule OceanconnectWeb.AuctionsChannelTest do
  use OceanconnectWeb.ChannelCase
  alias Oceanconnect.Utilities
  alias Oceanconnect.{Auctions}

  setup do
    buyer_company = insert(:company)
    supplier_company = insert(:company)

    buyer = insert(:user, company: buyer_company)
    supplier = insert(:user, company: supplier_company)
    non_participant = insert(:user)

    {:ok, %{supplier_id: Integer.to_string(supplier.id),
            buyer_id: Integer.to_string(buyer.id),
            non_participant_id: Integer.to_string(non_participant.id),
            non_participant: non_participant,
            buyer: buyer,
            supplier: supplier}}
  end

  describe "Auction Start" do
    setup(%{buyer: buyer, supplier: supplier}) do
      auction = insert(:auction, buyer: buyer, duration: 10 * 60_000)
      Auctions.set_suppliers_for_auction(auction, [supplier])
      current_time =  DateTime.utc_now()
      {:ok, duration} = Time.new(0, round(auction.duration / 60_000), 0, 0)
      {:ok, elapsed_time} = Time.new(0, 0, DateTime.diff(current_time, auction.auction_start), 0)
      time_remaining = Time.diff(duration, elapsed_time) * 1_000
      {:ok, _store} = Auctions.AuctionStore.start_link(auction.id)


      expected_payload = %{id: auction.id, state: %{status: :open, time_remaining: time_remaining, current_server_time: current_time}}
      {:ok, %{expected_payload: expected_payload, auction: auction}}
    end

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

  describe "Auction Ended" do
    setup(%{buyer: buyer, supplier: supplier}) do
      auction = insert(:auction, buyer: buyer, duration: 1_000)
      Auctions.set_suppliers_for_auction(auction, [supplier])
      {:ok, _store} = Auctions.AuctionStore.start_link(auction.id)
      expected_payload = %{id: auction.id, state: %{status: :decision, time_remaining: 0}}
      {:ok, %{expected_payload: expected_payload, auction: auction}}
    end

    test "buyers get notified when the auction ends", %{auction: auction, buyer: buyer, expected_payload: payload} do
      buyer_id = buyer.id
      channel = "user_auctions:#{buyer_id}"
      event = "auctions_update"

      @endpoint.subscribe(channel)

      Auctions.start_auction(auction)
      receive do
        %{event: ^event, payload: ^payload, topic: ^channel} ->
          assert true
      after
        2_000 -> assert false
      end
    end

    test "suppliers get notified when the auction ends", %{auction: auction, supplier: supplier, expected_payload: payload} do
      supplier_id = supplier.id
      channel = "user_auctions:#{supplier_id}"
      event = "auctions_update"

      @endpoint.subscribe(channel)

      Auctions.start_auction(auction)
      receive do
        %{event: ^event, payload: ^payload, topic: ^channel} ->
          assert true
      after
        2_000 -> assert false
      end
    end

    test "a non participant does not", %{auction: auction, non_participant: non_participant}  do
      non_participant_id = non_participant.id
      channel = "user_auctions:#{non_participant_id}"
      event = "auctions_update"

      @endpoint.subscribe(channel)

      Auctions.start_auction(auction)
      refute_receive %{event: ^event, payload: %{status: :decision}, topic: ^channel}
    end
  end
end
