defmodule Oceanconnect.Messages.MessagePayload do
  alias __MODULE__
  alias Oceanconnect.{Auctions, Messages, Repo}
  alias Oceanconnect.Auctions.{Auction, AuctionSuppliers}

  defstruct auction_id: nil,
            anonymous_bidding: false,
            buyer_id: nil,
            conversations: [],
            status: :pending,
            unseen_messages: nil,
            vessels: []

  def get_message_payloads_for_company(company_id) do
    company_id
    |> Auctions.list_participating_auctions()
    |> Enum.map(fn auction ->
      auction
      |> load_auction_info_for_message_payload()
      |> get_auction_messages_for_payload(company_id)
      |> add_unseen_message_totals()
    end)
  end

  defp load_auction_info_for_message_payload(%Auction{} = auction) do
    auction
    |> Repo.preload([:vessels])
    |> Map.take([:id, :anonymous_bidding, :buyer_id, :vessels])
    |> build_message_payload_struct()
    |> Map.merge(auction |> Auctions.get_auction_state!() |> Map.take([:status]))
  end

  defp build_message_payload_struct(messages_map) do
    __MODULE__
    |> struct(messages_map)
    |> Map.put(:auction_id, messages_map.id)
  end

  defp get_auction_messages_for_payload(message_payload, company_id) do
    Map.put(message_payload, :conversations, group_auction_messages(message_payload, company_id))
  end

  defp group_auction_messages(%{auction_id: auction_id} = message_payload, company_id) do
    auction_id
    |> Messages.list_auction_messages_for_company(company_id)
    |> Enum.group_by(&get_correspondence_company_id(&1, company_id))
    |> build_message_payload_with_supplier_name(message_payload, company_id)
  end

  defp get_correspondence_company_id(%{author_company_id: company_id, recipient_company_id: id}, company_id), do: id
  defp get_correspondence_company_id(%{author_company_id: id}, _company_id), do: id

  defp build_message_payload_with_supplier_name(messages_map, message_payload, company_id) do
    messages_map
    |> Enum.reduce([], fn({k, v}, acc) ->
      company_message_payload = %{
        company_name: AuctionSuppliers.get_name_or_alias(k, message_payload),
        messages: sanitize_messages(v, company_id),
        unseen_messages: count_unseen_messages(v, company_id)
      }
      [company_message_payload | acc]
    end)
    |> Enum.sort_by(& &1.company_name)
  end

  defp sanitize_messages(messages, company_id) do
    Enum.map(messages, fn(message) ->
      message
      |> Map.take([:id, :content, :has_been_seen, :inserted_at])
      |> Map.put(:author_is_me, message.author_company_id == company_id)
    end)
  end

  defp count_unseen_messages(messages, company_id) do
    Enum.count(messages, &unseen_by_recipient?(&1, company_id))
  end

  defp unseen_by_recipient?(%{author_company_id: company_id}, company_id), do: false
  defp unseen_by_recipient?(%{has_been_seen: has_been_seen}, _company_id), do: !has_been_seen

  defp add_unseen_message_totals(%MessagePayload{conversations: conversations} = message_payload) do
    unseen_messages = Enum.reduce(conversations, 0, fn(conversation, acc) -> acc + conversation.unseen_messages end)
    Map.put(message_payload, :unseen_messages, unseen_messages)
  end
end
