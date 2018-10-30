defmodule OceanconnectWeb.ChatfishChannelTest do
  use OceanconnectWeb.ChannelCase
  alias Oceanconnect.{Accounts, Auctions}
  alias OceanconnectWeb.ChatfishChannel


  setup do
    buyer_company = insert(:company, is_supplier: true)
    buyer_users = insert_list(2, :user, company: buyer_company)
    supplier_companies = insert_list(2, :company, is_supplier: true)
    supplier_users = for company <- supplier_companies do
      :user
      |> insert(company: company)
      |> Accounts.load_company_on_user()
    end

    [supplier, supplier2] = supplier_companies

    auction =
      :auction
      |> insert(buyer: buyer_company, suppliers: [supplier])
      |> Auctions.fully_loaded()

    auction2 =
      :auction
      |> insert(buyer: buyer_company, suppliers: [supplier2])
      |> Auctions.fully_loaded()

    messages = insert_list(3, :message, auction: auction, author_company: hd(supplier_companies), recipient_company: buyer)

    {:ok, auction: auction, auction2: auction2, buyer_company: buyer_company, buyer_users: buyer_users, supplier_companies: supplier_companies, supplier_users: supplier_users, messages: messages}
  end

  test "supplier can only see messages between them and buyer for auctions they participate in", %{
    auction: auction,
    auction2: auction2,
    supplier_users: [supplier_user | _]
  } do
    channel = "user_messaging:#{Integer.to_string(supplier_user.company_id)}"
    event = "messages_update"

    {:ok, supplier_token, _claims} = Oceanconnect.Guardian.encode_and_sign(supplier_user)

    {:ok, _, _socket} =
      subscribe_and_join(socket(), ChatfishChannel, channel, %{"token" => supplier_token})

    auction_id = auction.id
    auction2_id = auction2.id
    receive do
      %Phoenix.Socket.Broadcast{
        event: ^event,
        payload: %{
          messaging_payloads: messaging_payloads
        },
        topic: ^channel
      } ->
        auction_ids = Enum.map(messaging_payloads, &(&1.id))
        assert Enum.member?(auction_ids, auction_id)
        refute Enum.member?(auction_ids, auction2_id)

    after 5000 ->
        assert false, "Expected message received nothing."
    end
  end


  test "buyer can see all buyer to supplier messages for their auctions", %{
    auction: auction,
    auction2: auction2,
    buyer_users: [buyer_user | _]
  } do
    channel = "user_messaging:#{Integer.to_string(buyer_user.company_id)}"
    event = "messages_update"

    {:ok, buyer_token, _claims} = Oceanconnect.Guardian.encode_and_sign(buyer_user)
    {:ok, _, _socket} =
      subscribe_and_join(socket(), ChatfishChannel, channel, %{"token" => buyer_token})

    auction_id = auction.id
    auction2_id = auction2.id
    receive do
      %Phoenix.Socket.Broadcast{
        event: ^event,
        payload: %{
          messaging_payloads: messaging_payloads
        },
        topic: ^channel
      } ->
        auction_ids = Enum.map(messaging_payloads, &(&1.id))
        assert Enum.member?(auction_ids, auction_id)
        assert Enum.member?(auction_ids, auction2_id)
    after 5000 ->
        assert false, "Expected message received nothing."
    end
  end
end
