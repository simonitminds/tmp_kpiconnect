defmodule Oceanconnect.Messages.MessagePayload do
  import Ecto.Query

  alias __MODULE__
  alias Oceanconnect.{Auctions, Messages, Repo}
  alias Oceanconnect.Auctions.{Auction, AuctionSuppliers}

  defstruct auction_id: nil,
            anonymous_bidding: false,
            status: :pending,
            vessels: [],
            messages: []

  def get_message_payloads_for_company(company_id) do
    company_id
    |> Auctions.list_participating_auctions()
    |> Enum.map(fn auction ->
      auction
      |> load_auction_info_for_message_payload()
      |> get_auction_messages_for_payload(company_id)
    end)
  end

  defp load_auction_info_for_message_payload(%Auction{} = auction) do
    auction
    |> Repo.preload([:vessels])
    |> Map.take([:id, :anonymous_bidding, :buyer_id, :vessels])
    |> Map.put(:auction_id, &(&1.id))
    |> Map.delete(:id)
    |> Map.merge(auction |> Auctions.get_auction_state!() |> Map.take([:status]))
  end

  defp get_auction_messages_for_payload(message_payload, company_id) do
    Map.put(message_payload, :messages, group_auction_messages(message_payload, company_id))
  end

  defp group_auction_messages(%{id: auction_id} = message_payload, company_id) do
    auction_id
    |> Messages.list_auction_messages_for_company(company_id)
    |> Enum.group_by(&get_correspondence_company_id(&1, company_id))
    |> build_message_payload_with_supplier_name(message_payload)
  end

  defp get_correspondence_company_id(%{author_company_id: company_id, recipient_company_id: id}, company_id), do: id
  defp get_correspondence_company_id(%{author_company_id: id}, _company_id), do: id

  defp build_message_payload_with_supplier_name(messages_map, message_payload) do
    messages_map
    |> Enum.reduce([], fn({k, v}, acc) ->
      company_message_payload = %{
      company_name: AuctionSuppliers.get_name_or_alias(k, message_payload),
      messages: v
    }
      [company_message_payload | acc]
    end)
    |> Enum.sort_by(& &1.company_name)
  end
end
