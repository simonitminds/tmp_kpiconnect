defmodule Oceanconnect.MessagesTest do
  use Oceanconnect.DataCase

  alias Oceanconnect.Messages
  alias Oceanconnect.Messages.Message

  describe "messages" do
    @valid_attrs %{content: "some content", has_been_seen: true}
    @update_attrs %{content: "some updated content", has_been_seen: false}
    @invalid_attrs %{content: nil, has_been_seen: nil}

    def message_fixture(attrs \\ %{}) do
      {:ok, message} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Messages.create_message()

      message
    end

    test "list_messages/0 returns all messages" do
      message = message_fixture()
      assert Messages.list_messages() == [message]
    end

    test "get_message!/1 returns the message with given id" do
      message = message_fixture()
      assert Messages.get_message!(message.id) == message
    end

    test "create_message/1 with valid data creates a message" do
      assert {:ok, %Message{} = message} = Messages.create_message(@valid_attrs)
      assert message.content == "some content"
      assert message.has_been_seen == true
    end

    test "create_message/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Messages.create_message(@invalid_attrs)
    end

    test "update_message/2 with valid data updates the message" do
      message = message_fixture()
      assert {:ok, message} = Messages.update_message(message, @update_attrs)
      assert %Message{} = message
      assert message.content == "some updated content"
      assert message.has_been_seen == false
    end

    test "update_message/2 with invalid data returns error changeset" do
      message = message_fixture()
      assert {:error, %Ecto.Changeset{}} = Messages.update_message(message, @invalid_attrs)
      assert message == Messages.get_message!(message.id)
    end

    test "delete_message/1 deletes the message" do
      message = message_fixture()
      assert {:ok, %Message{}} = Messages.delete_message(message)
      assert_raise Ecto.NoResultsError, fn -> Messages.get_message!(message.id) end
    end

    test "change_message/1 returns a message changeset" do
      message = message_fixture()
      assert %Ecto.Changeset{} = Messages.change_message(message)
    end
  end

  describe "list_messages_for_company/2" do
    test "returns all messages where the given company is either an author or the recipient" do
      company = insert(:company)
      auction = insert(:auction, suppliers: [company])

      insert_list(4, :message,
        auction: auction,
        author_company: auction.buyer,
        recipient_company: company
      )

      assert length(Messages.list_auction_messages_for_company(auction.id, company.id)) == 4

      assert Enum.all?(
               Messages.list_auction_messages_for_company(auction.id, company.id),
               &(&1.recipient_company_id == company.id)
             )
    end

    test "does not return messages that don't belong to the given company" do
      supplier_company = insert(:company)
      supplier_company2 = insert(:company)
      auction = insert(:auction, suppliers: [supplier_company, supplier_company2])

      insert_list(4, :message,
        auction: auction,
        author_company: auction.buyer,
        recipient_company: supplier_company
      )

      insert_list(3, :message,
        auction: auction,
        author_company: auction.buyer,
        recipient_company: supplier_company2
      )

      refute Enum.all?(
               Messages.list_auction_messages_for_company(auction.id, supplier_company.id),
               &(&1.recipient_company_id == supplier_company2.id)
             )
    end

    test "messages sorted oldest to newest" do
      supplier_company = insert(:company)
      auction = insert(:auction, suppliers: [supplier_company])

      %{id: id1} =
        insert(:message,
          auction: auction,
          author_company: auction.buyer,
          recipient_company: supplier_company
        )

      %{id: id2} =
        insert(:message,
          auction: auction,
          author_company: auction.buyer,
          recipient_company: supplier_company
        )

      assert Enum.map(
               Messages.list_auction_messages_for_company(auction.id, supplier_company.id),
               & &1.id
             ) == [id1, id2]
    end
  end
end
