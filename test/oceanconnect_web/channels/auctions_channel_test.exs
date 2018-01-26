defmodule OceanconnectWeb.AuctionsChannelTest do
  use OceanconnectWeb.ChannelCase
  alias OceanconnectWeb.{AuctionsChannel, UserSocket}
  alias Oceanconnect.{Auctions}
  alias OceanconnectWeb.Plugs.Auth
  alias Oceanconnect.Auctions.AuctionStore.AuctionState

  setup do
    buyer_company = insert(:company)
    supplier_company = insert(:company)

    buyer = insert(:user, company: buyer_company)
    supplier = insert(:user, company: supplier_company)
    non_participant = insert(:user)

    auction = insert(:auction, buyer: buyer)
    Auctions.set_suppliers_for_auction(auction, [supplier])
    {:ok, _store} = Auctions.AuctionStore.start_link(auction.id)

    conn = conn()
    buyer_token = Auth.generate_user_token(conn, buyer)
    supplier_token = Auth.generate_user_token(conn, supplier)
    non_participant_token = Auth.generate_user_token(conn, non_participant)

    {:ok, supplier_socket} = connect(UserSocket, %{token: supplier_token})
    subscribe_and_join(supplier_socket, AuctionsChannel, "auctions:lobby")

    {:ok, buyer_socket} = connect(UserSocket, %{token: buyer_token})
    subscribe_and_join(buyer_socket, AuctionsChannel, "auctions:lobby")

    {:ok, non_participant_socket} = connect(UserSocket, %{token: non_participant_token})
    subscribe_and_join(non_participant_socket, AuctionsChannel, "auctions:lobby")

    {:ok, %{
        supplier_id: Integer.to_string(supplier.id),
        buyer_id: Integer.to_string(buyer.id),
        non_participant_id: Integer.to_string(non_participant.id),
        auction: auction
    }}
  end


  test "broadcasts are pushed to the buyer", %{buyer_id: buyer_id,
                                                auction: auction} do
    auction_id = auction.id
    expected_payload = %AuctionState{auction_id: auction_id, status: :open}
    channel = "user_socket:#{buyer_id}:auctions:lobby"
    event = "auctions_update"

    @endpoint.subscribe(channel)
    Auctions.start_auction(auction)
    assert_broadcast ^event, ^expected_payload
  end

  test "broadcasts are pushed to the supplier", %{supplier_id: supplier_id,
                                               auction: auction} do
    auction_id = auction.id
    expected_payload = %AuctionState{auction_id: auction_id, status: :open}
    channel = "user_socket:#{supplier_id}:auctions:lobby"
    event = "auctions_update"

    @endpoint.subscribe(channel)
    Auctions.start_auction(auction)
    assert_broadcast ^event, ^expected_payload
  end

  test "broadcasts are pushed to a non_participant", %{non_participant_id: non_participant_id,
                                                  auction: auction} do
    auction_id = auction.id
    expected_payload = %AuctionState{auction_id: auction_id, status: :open}
    channel = "user_socket:#{non_participant_id}:auctions:lobby"
    event = "auctions_update"

    @endpoint.subscribe(channel)
    Auctions.start_auction(auction)
    refute_broadcast ^event, ^expected_payload
  end
end
