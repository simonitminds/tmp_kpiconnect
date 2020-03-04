defmodule Oceanconnect.Messages.MessagePayload do
  import Oceanconnect.Auctions.Guards

  alias Oceanconnect.{Accounts, Auctions, Messages}
  alias Oceanconnect.Auctions.{AuctionSuppliers}

  defstruct auction_id: nil,
            auction: nil,
            anonymous_bidding: false,
            buyer_id: nil,
            conversations: [],
            status: :pending,
            unseen_messages: 0

  def get_message_payloads_for_company(company_id) do
    participating_auctions =
      company_id
      |> Auctions.list_participating_auctions(false)
      |> Kernel.++(Auctions.list_participating_auctions(company_id, true))
      |> Enum.sort_by(& &1.id, &>=/2)

    Enum.map(participating_auctions, &get_message_payload_for_auction(&1, company_id))
  end

  defp get_message_payload_for_auction(
         %struct{
           id: auction_id,
           anonymous_bidding: anonymous_bidding,
           buyer_id: buyer_id,
           suppliers: _suppliers
         } = auction,
         company_id
       )
       when is_auction(struct) do
    %{status: status} = Auctions.get_auction_state!(auction)

    conversations = conversations_by_company(auction, company_id)

    %__MODULE__{
      auction_id: auction_id,
      auction: auction,
      anonymous_bidding: anonymous_bidding,
      buyer_id: buyer_id,
      conversations: conversations,
      status: status,
      unseen_messages: Enum.reduce(conversations, 0, fn c, acc -> acc + c.unseen_messages end)
    }
  end

  defp conversations_by_company(auction, company_id) do
    auction.id
    |> Messages.list_auction_messages_for_company(company_id)
    |> Enum.group_by(&get_recipient_id(&1, company_id))
    |> ensure_all_companies_present(auction, company_id)
    |> build_conversations_payload(auction, company_id)
  end

  defp get_recipient_id(
         %{author_company_id: company_id, recipient_company_id: id},
         company_id
       ),
       do: id

  defp get_recipient_id(%{author_company_id: id}, _company_id), do: id

  defp ensure_all_companies_present(
         conversations,
         %{buyer_id: buyer_id, suppliers: suppliers},
         buyer_id
       ) do
    supplier_ids = Enum.map(suppliers, & &1.id)

    [buyer_id | supplier_ids]
    |> Enum.reduce(conversations, fn id, acc ->
      Map.put_new(acc, id, [])
    end)
  end

  defp ensure_all_companies_present(
         conversations,
         %{buyer_id: buyer_id},
         _company_id
       ) do
    Map.put_new(conversations, buyer_id, [])
  end

  defp build_conversations_payload(conversations, auction, company_id) do
    conversations
    |> Enum.reduce([], fn {recipient_id, messages}, acc ->
      payload = %{
        company_name: AuctionSuppliers.get_name_or_alias(recipient_id, auction),
        messages: sanitize_messages(messages, company_id, auction),
        unseen_messages: count_unseen_messages(messages, company_id)
      }

      [payload | acc]
    end)
    |> Enum.sort_by(& &1.company_name)
  end

  defp sanitize_messages(messages, company_id, %{anonymous_bidding: anon}) do
    Enum.map(messages, fn message ->
      message
      |> Map.take([:id, :content, :has_been_seen, :inserted_at])
      |> Map.put(:author_is_me, message.author_company_id == company_id)
      |> Map.put(:user, get_user_name(message, company_id, anon))
    end)
  end

  defp get_user_name(
         %{author_id: author_id, author_company_id: company_id},
         company_id,
         _anon
       ),
       do: Accounts.get_user_name!(author_id)

  defp get_user_name(_message, _company_id, true = _anon), do: "Anonymous"

  defp get_user_name(%{author_id: author_id}, _company_id, _anon),
    do: Accounts.get_user_name!(author_id)

  defp count_unseen_messages(messages, company_id) do
    Enum.count(messages, &unseen_by_recipient?(&1, company_id))
  end

  defp unseen_by_recipient?(%{author_company_id: company_id}, company_id), do: false
  defp unseen_by_recipient?(%{has_been_seen: has_been_seen}, _company_id), do: !has_been_seen
end
