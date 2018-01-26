defmodule OceanconnectWeb.AuctionsChannelTest do
  use OceanconnectWeb.ChannelCase
  alias OceanconnectWeb.AuctionsChannel
  alias Oceanconnect.{Auctions, Accounts}
  alias OceanconnectWeb.Plugs.Auth

  defp conn() do
    %Plug.Conn{}
    |> Plug.Conn.put_private(:phoenix_endpoint, OceanconnectWeb.Endpoint)
  end

  setup do
    buyer_company = insert(:company)
    supplier_company = insert(:company)

    buyer = insert(:user, company: buyer_company)
    supplier = insert(:user, company: supplier_company)
    non_participatant = insert(:user)

    auction = insert(:auction, buyer: buyer)
    Auctions.set_suppliers_for_auction(auction, [supplier])
    {:ok, store} = Auctions.AuctionStore.start_link(auction.id)

    conn = conn()
    buyer_token = Auth.generate_user_token(conn, buyer)
    supplier_token = Auth.generate_user_token(conn, supplier)
    non_participatant_token = Auth.generate_user_token(conn, non_participatant)

    {:ok, _, supplier_socket} =
      socket("user_id", %{token: supplier_token})
      |> subscribe_and_join(AuctionsChannel, "auctions:lobby")

    {:ok, _, buyer_socket} =
      socket("user_id", %{token: buyer_token})
      |> subscribe_and_join(AuctionsChannel, "auctions:lobby")

    {:ok, _, non_participatant_socket} =
      socket("user_id", %{token: non_participatant_token})
      |> subscribe_and_join(AuctionsChannel, "auctions:lobby")


    {:ok, %{
        supplier_socket: supplier_socket,
        buyer_socket: buyer_socket,
        non_participant_socket: non_participatant_socket,
        auction: auction
    }}
  end


  test "broadcasts are pushed to the client", %{supplier_socket: supplier_socket,
                                                buyer_socket: buyer_socket,
                                                non_participant_socket: non_participatant_socket,
                                                auction: auction} do
    Auctions.start_auction(auction)
    auction_id = auction.id
    assert_push "auctions:lobby", %{id: auction_id, status: :open}
  end
end
