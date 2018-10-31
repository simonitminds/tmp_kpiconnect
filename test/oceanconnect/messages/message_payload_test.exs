defmodule Oceanconnect.Messages.MessagePayloadTest do
  use Oceanconnect.DataCase

  alias Oceanconnect.{Messages, Auctions}
  alias Oceanconnect.Auctions.AuctionSupervisor
  alias Oceanconnect.Messages.{Message, MessagePayload}

  describe "get_message_payloads_for_company/1" do
    setup do
      buyer_company = insert(:company)
      supplier_company = insert(:company)
      supplier_company2 = insert(:company)
      vessels = insert_list(2, :vessel)

      auction =
        :auction
        |> insert(
          buyer: buyer_company,
          vessels: vessels,
          suppliers: [supplier_company]
        )
        |> Auctions.fully_loaded()

      {:ok, _pid} =
        start_supervised(
          {AuctionSupervisor,
            {auction, %{exclude_children: [:auction_reminder_timer, :auction_scheduler]}}}
        )

      Auctions.start_auction(auction)

      auction2 =
        :auction
        |> insert(
          buyer: buyer_company,
          vessels: vessels,
          suppliers: [supplier_company2]
        )
        |> Auctions.fully_loaded()

      insert_list(3, :message, auction: auction, author_company: buyer_company, recipient_company: supplier_company)
      insert_list(4, :message, auction: auction2, author_company: buyer_company, recipient_company: supplier2_company)

      {:ok, %{buyer_company: buyer_company, supplier_company: supplier_company, supplier_company2: supplier_company2, vessels: vessels, auction: auction, auction2: auction2}}
    end

    test "returns message payloads for auctions that a company is participating in", %{buyer_company: author_company, supplier_company: recipient_company, auction: auction, auction2: auction2, vessels: vessels} do
      # assert length of payload messages
      # assertions for correct auctions, vessels, and status
      message_payloads_for_author = MessagePayload.get_message_payloads_for_company(author_company.id)
      # assert length(Enum.flat_map(message_payloads_for_author, &(&1.messages))) == 3
      assert Enum.all?(message_payloads_for_author, &(&1.auction_id == auction.id))

      messages_for_recipient = MessagePayload.get_message_payloads_for_company(recipient_company.id)
      # assert length(Enum.flat_map(message_payloads_for_recipient, &(&1.messages))) == 3
      assert Enum.all?(messages_for_recipient, &(&1.auction_id == auction.id))
      refute Enum.all?(messages_for_recipient, &(&1.auction_id == auction2.id))
    end

    test "does not return message payloads for auctions a company is not participating in" do

    end
  end
end
