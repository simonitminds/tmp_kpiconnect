defmodule OceanconnectWeb.ChatfishChannel do
  use OceanconnectWeb, :channel

  alias Oceanconnect.Auctions.Auction

  def join("user_messaging:" <> id, payload, socket) do
    if authorized?(socket, id, payload) do
      send(self, {:messages_update, "user_messaging:" <> id, String.to_integer(id)})
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_info({:messages_update, channel, company_id}, socket) do
    message_payloads = get_messages_for_company(company_id)
    broadcast! socket, "messages_update", %{message_payloads: message_payloads}
    {:noreply, socket}
  end

  defp get_messages_for_company(company_id) do
    company_id
    |> Oceanconnect.Auctions.list_participating_auctions()
    |> Enum.map(fn auction ->
      auction
      |> Oceanconnect.Auctions.fully_loaded()
      |> get_auction_messages(company_id)
    end)
  end

  defp get_auction_messages(%Auction{buyer_id: company_id}, company_id), do: "buyer"
  defp get_auction_messages(_auction, _company_id), do: "supplier"

  # def handle_info({:list_auctions}, socket) do
  #   company_id = socket.assigns[:company_id]
  #   push socket, "auction_list", %{auctions: get_auctions_for_company(company_id)}
  #   {:noreply, socket}
  # end
  #
  # defp get_auctions_for_company(company_id) do
  #   company_id
  #   |> Oceanconnect.Auctions.list_participating_auctions()
  #   |> Enum.map(fn auction ->
  #     auction
  #     |> Oceanconnect.Auctions.fully_loaded()
  #     |> Oceanconnect.Auctions.AuctionPayload.get_auction_payload!(company_id)
  #   end)
  # end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  # def handle_in("ping", payload, socket) do
  #   {:reply, {:ok, payload}, socket}
  # end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (auctions:lobby).
  # def handle_in("shout", payload, socket) do
  #   broadcast socket, "shout", payload
  #   {:noreply, socket}
  # end

  # Add authorization logic here as required.
  defp authorized?(socket, id, %{"token" => token}) do
    authed = Guardian.Phoenix.Socket.authenticate(socket, Oceanconnect.Guardian, token)

    case authed do
      {:ok, authed_socket} ->
        company_id = Guardian.Phoenix.Socket.current_resource(authed_socket).company_id
        if company_id == String.to_integer(id), do: true, else: false

      {:error, _reason} ->
        false
    end
  end

  defp authorized?(_, _, _), do: false
end
