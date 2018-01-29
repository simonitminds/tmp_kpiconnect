defmodule OceanconnectWeb.AuctionsChannelTest do
  use OceanconnectWeb.ChannelCase
  alias Oceanconnect.{Auctions}

  setup do
    buyer_company = insert(:company)
    supplier_company = insert(:company)

    buyer = insert(:user, company: buyer_company)
    supplier = insert(:user, company: supplier_company)
    non_participant = insert(:user)

    auction = insert(:auction, buyer: buyer, duration: 10)
    Auctions.set_suppliers_for_auction(auction, [supplier])
    current_time =  DateTime.utc_now()
    time_remaining = Time.diff(Time.new(0, auction.duration, 0, 0) - Time.new(0, 0, DateTime.diff(current_time, auction.auction_start), 0))
    expected_payload = %{id: auction.id, state: %{status: :open, time_remaining: time_remaining, current_server_time: current_time}}
    {:ok, _store} = Auctions.AuctionStore.start_link(auction.id)

    {:ok, %{supplier_id: Integer.to_string(supplier.id),
            buyer_id: Integer.to_string(buyer.id),
            non_participant_id: Integer.to_string(non_participant.id),
            non_participant: non_participant,
            auction: auction,
            expected_payload: expected_payload
           }}
  end


  test "broadcasts are pushed to the buyer", %{buyer_id: buyer_id,
                                               auction: auction,
                                               expected_payload: expected_payload} do
    channel = "user_auctions:#{buyer_id}"
    event = "auctions_update"

    @endpoint.subscribe(channel)
    Auctions.start_auction(auction)

    assert_broadcast ^event, ^expected_payload
  end

  test "broadcasts are pushed to the supplier", %{supplier_id: supplier_id,
                                                  auction: auction,
                                                  expected_payload: expected_payload} do
    channel = "user_auctions:#{supplier_id}"
    event = "auctions_update"

    @endpoint.subscribe(channel)
    Auctions.start_auction(auction)

    assert_broadcast ^event, ^expected_payload
  end

  test "broadcasts are pushed to a non_participant", %{non_participant_id: non_participant_id,
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

  test "auction start begins time remaining countdown", %{buyer_id: buyer_id, auction: auction} do
    channel = "user_auctions:#{buyer_id}"
    event = "auctions_update"

    @endpoint.subscribe(channel)
    Auctions.start_auction(auction)

    assert_broadcast ^event, ^expected_payload
  end
end
