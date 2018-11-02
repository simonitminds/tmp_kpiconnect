defmodule OceanconnectWeb.ChatfishChannelTest do
  use OceanconnectWeb.ChannelCase
  alias Oceanconnect.{Auctions, Repo}
  alias Oceanconnect.Messages.{Message, MessagePayload}
  alias OceanconnectWeb.ChatfishChannel


  setup do
    buyer_company = insert(:company, is_supplier: true)
    buyer = insert(:user, company: buyer_company)
    supplier_company = insert(:company, is_supplier: true)
    supplier = insert(:user, company: supplier_company)

    auction =
      :auction
      |> insert(buyer: buyer_company, suppliers: [supplier_company])
      |> Auctions.fully_loaded()

    messages = insert_list(3, :message, auction: auction, author_company: buyer_company, recipient_company: supplier_company)

    {:ok, auction: auction, buyer: buyer, messages: messages, supplier: supplier}
  end

  test "supplier can get message payloads", %{supplier: supplier} do
    channel = "user_messages:#{supplier.company_id}"
    event = "messages_update"

    {:ok, supplier_token, _claims} = Oceanconnect.Guardian.encode_and_sign(supplier)

    {:ok, _, _socket} =
      subscribe_and_join(socket(), ChatfishChannel, channel, %{"token" => supplier_token})

    receive do
      %Phoenix.Socket.Broadcast{
        event: ^event,
        payload: %{
          message_payloads: message_payloads
        },
        topic: ^channel
      } ->
        assert %MessagePayload{} = hd(message_payloads)

    after 5000 ->
      assert false, "Expected message received nothing."
    end
  end

  test "buyer can get message payloads", %{buyer: buyer} do
    channel = "user_messages:#{buyer.company_id}"
    event = "messages_update"

    {:ok, buyer_token, _claims} = Oceanconnect.Guardian.encode_and_sign(buyer)
    {:ok, _, _socket} =
      subscribe_and_join(socket(), ChatfishChannel, channel, %{"token" => buyer_token})

    receive do
      %Phoenix.Socket.Broadcast{
        event: ^event,
        payload: %{
          message_payloads: message_payloads
        },
        topic: ^channel
      } ->
        assert %MessagePayload{} = hd(message_payloads)
    after 5000 ->
      assert false, "Expected message received nothing."
    end
  end

  test "recipient can mark messages as seen", %{messages: messages, supplier: supplier} do
    channel = "user_messages:#{supplier.company_id}"
    event = "seen"

    [%{id: message_id} | unseen_messages] = messages
    {:ok, supplier_token, _claims} = Oceanconnect.Guardian.encode_and_sign(supplier)

    {:ok, _, socket} =
      subscribe_and_join(socket(), ChatfishChannel, channel, %{"token" => supplier_token})

    push(socket, event, %{"ids" => [message_id]})

    :timer.sleep(100)
    assert Enum.all?(unseen_messages, &Repo.get(Message, &1.id).has_been_seen == false)
    assert Repo.get(Message, message_id).has_been_seen
  end

  test "cannot mark messages as seen if not recipient", %{messages: messages, buyer: buyer} do
    channel = "user_messages:#{buyer.company_id}"
    event = "seen"

    [%{id: message_id} | _tail] = messages
    {:ok, buyer_token, _claims} = Oceanconnect.Guardian.encode_and_sign(buyer)

    {:ok, _, socket} =
      subscribe_and_join(socket(), ChatfishChannel, channel, %{"token" => buyer_token})

    push(socket, event, %{"ids" => [message_id]})

    :timer.sleep(100)
    assert Enum.all?(messages, &Repo.get(Message, &1.id).has_been_seen == false)
  end

  test "author can send a message that recipient receives", %{
    auction: %{id: auction_id},
    buyer: buyer,
    supplier: supplier
  } do
    channel = "user_messages:#{supplier.company_id}"
    event = "send"

    {:ok, supplier_token, _claims} = Oceanconnect.Guardian.encode_and_sign(supplier)

    {:ok, _, socket} =
      subscribe_and_join(socket(), ChatfishChannel, channel, %{"token" => supplier_token})

    push(socket, event, %{"auctionId" => auction_id, "recipient" => buyer.company_id, "content" => "Hello!"})

    :timer.sleep(100)
    recipient_channel = "user_messages:#{buyer.company_id}"
    recipient_event = "messages_update"

    {:ok, buyer_token, _claims} = Oceanconnect.Guardian.encode_and_sign(buyer)

    {:ok, _, _socket} =
      subscribe_and_join(socket(), ChatfishChannel, recipient_channel, %{"token" => buyer_token})

    receive do
      %Phoenix.Socket.Broadcast{
        event: ^recipient_event,
        payload: %{
          message_payloads: [message_payload]
        },
        topic: ^recipient_channel
      } ->
        assert message_payload.auction_id == auction_id

        [conversation | _] = message_payload.conversations
        assert conversation.company_name == supplier.company.name

        %{messages: [%Message{content: content} | _tail]} = conversation
        assert content == "Hello!"
    after 5000 ->
      assert false, "Expected message received nothing."
    end
  end
end
