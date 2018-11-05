defmodule Oceanconnect.Messages.MessagePayloadTest do
  use Oceanconnect.DataCase

  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.AuctionSupervisor
  alias Oceanconnect.Messages.MessagePayload

  describe "get_message_payloads_for_company/1" do
    setup do
      buyer_company = insert(:company)
      supplier_company = insert(:company)
      supplier_company2 = insert(:company)
      supplier_company3 = insert(:company)

      auction =
        :auction
        |> insert(
          buyer: buyer_company,
          suppliers: [supplier_company, supplier_company3]
        )
        |> Auctions.fully_loaded()

      {:ok, _pid} =
        start_supervised(
          {AuctionSupervisor,
            {auction, %{exclude_children: [:auction_reminder_timer, :auction_scheduler]}}}
        )

      Auctions.start_auction(auction)

      anon_auction =
        :auction
        |> insert(
          anonymous_bidding: true,
          buyer: buyer_company,
          suppliers: [supplier_company, supplier_company2]
        )
        |> Auctions.create_supplier_aliases()
        |> Auctions.fully_loaded()

      buyer_company2 = insert(:company)
      auction2 =
        :auction
        |> insert(
          buyer: buyer_company2,
          suppliers: [supplier_company3]
        )
        |> Auctions.fully_loaded()

      insert_list(3, :message, auction: auction, author_company: buyer_company, recipient_company: supplier_company)
      insert_list(4, :message, auction: anon_auction, author_company: buyer_company, recipient_company: supplier_company2)
      insert_list(2, :message, auction: anon_auction, author_company: supplier_company, recipient_company: buyer_company)

      {:ok, %{anon_auction: anon_auction, auction: auction, auction2: auction2, buyer_company: buyer_company, supplier_company: supplier_company, supplier_company2: supplier_company2, supplier_company3: supplier_company3}}
    end

    test "returns message payloads for a buyer's auctions", %{anon_auction: anon_auction, auction: auction, buyer_company: buyer_company, supplier_company: supplier_company} do
      message_payloads_for_company = MessagePayload.get_message_payloads_for_company(buyer_company.id)
      assert length(Enum.flat_map(message_payloads_for_company, fn message_payload ->
        Enum.flat_map(message_payload.conversations, &(&1.messages))
      end)) == 9
      assert Enum.all?(message_payloads_for_company, &(&1.auction_id == auction.id or &1.auction_id == anon_auction.id))
      assert Enum.map(message_payloads_for_company, & &1.unseen_messages) == [0, 2]

      message_payload_for_anon_auction = Enum.find(message_payloads_for_company, & &1.auction_id == anon_auction.id)
      assert %MessagePayload{} = message_payload_for_anon_auction
      assert length(message_payload_for_anon_auction.conversations) == 2

      vessel_names = Enum.map(anon_auction.vessels, & &1.name)
      assert Enum.all?(message_payload_for_anon_auction.vessels, & &1.name in vessel_names)

      anon_auction_supplier_alias_name = Enum.find(anon_auction.suppliers, & &1.id == supplier_company.id).alias_name
      assert Enum.find(message_payload_for_anon_auction.conversations, & &1.company_name == anon_auction_supplier_alias_name).unseen_messages == 2

      assert message_payload_for_anon_auction.suppliers == []
      [message | _] = hd(message_payload_for_anon_auction.conversations).messages
      refute Enum.any?([:author_id, :author_compnay_id, :recipient_company_id], &Map.has_key?(message, &1))
    end

    test "returns message payloads for a supplier's auctions that excludes other suppliers", %{anon_auction: anon_auction, auction: auction, supplier_company: supplier_company} do
      message_payloads_for_company = MessagePayload.get_message_payloads_for_company(supplier_company.id)
      assert length(Enum.flat_map(message_payloads_for_company, fn message_payload ->
        Enum.flat_map(message_payload.conversations, &(&1.messages))
      end)) == 5
      assert Enum.all?(message_payloads_for_company, &(&1.auction_id == auction.id or &1.auction_id == anon_auction.id))
      assert Enum.map(message_payloads_for_company, & &1.unseen_messages) == [3, 0]

      message_payload_for_anon_auction = Enum.find(message_payloads_for_company, & &1.auction_id == anon_auction.id)
      assert length(message_payload_for_anon_auction.conversations) == 1
    end

    test "does not return message payloads for auctions a company is not participating in", %{anon_auction: anon_auction, supplier_company2: supplier_company2} do
      message_payloads_for_company = MessagePayload.get_message_payloads_for_company(supplier_company2.id)
      assert length(Enum.flat_map(message_payloads_for_company, fn message_payload ->
        Enum.flat_map(message_payload.conversations, &(&1.messages))
      end)) == 4
      assert Enum.all?(message_payloads_for_company, &(&1.auction_id == anon_auction.id))
    end

    test "returns aliased names for buyer in an anonymous auction", %{anon_auction: %{id: auction_id}, buyer_company: buyer_company, supplier_company2: %{name: supplier_name}} do
      buyer_message_payload_for_anon_auction =
        buyer_company.id
        |> MessagePayload.get_message_payloads_for_company()
        |> Enum.find(& &1.auction_id == auction_id)
      refute hd(buyer_message_payload_for_anon_auction.conversations).company_name == supplier_name
    end

    test "buyer's conversation list includes supplier with no correspondence", %{auction: %{id: auction_id}, buyer_company: buyer_company, supplier_company3: %{name: supplier_name}} do
      buyer_message_payload_for_auction =
        buyer_company.id
        |> MessagePayload.get_message_payloads_for_company()
        |> Enum.find(& &1.auction_id == auction_id)
      assert supplier_name in Enum.map(buyer_message_payload_for_auction.conversations, & &1.company_name)
    end

    test "supplier's conversation list includes buyer with no correspondence", %{auction2: %{id: auction_id, buyer: %{name: buyer_name}}, supplier_company3: supplier_company} do
      supplier_message_payload_for_auction =
        supplier_company.id
        |> MessagePayload.get_message_payloads_for_company()
        |> Enum.find(& &1.auction_id == auction_id)
      assert buyer_name in Enum.map(supplier_message_payload_for_auction.conversations, & &1.company_name)
    end
  end
end
