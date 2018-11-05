defmodule OceanconnectWeb.ChatfishChannel do
  use OceanconnectWeb, :channel

  alias Oceanconnect.Messages
  alias Oceanconnect.Messages.{Message, MessagePayload}

  def join("user_messages:" <> id, %{"token" => token}, socket) do
    if authed_socket = authorized?(socket, id, token) do
      send(self(), {:initial_payloads, String.to_integer(id)})
      {:ok, authed_socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_info({:initial_payloads, company_id}, socket) do
    message_payloads = MessagePayload.get_message_payloads_for_company(company_id)
    broadcast!(socket, "messages_update", %{message_payloads: message_payloads})
    {:noreply, socket}
  end

  def handle_info({:messages_update, company_id}, socket) do
    message_payloads = MessagePayload.get_message_payloads_for_company(company_id)
    OceanconnectWeb.Endpoint.broadcast("user_messages:#{company_id}", "messages_update", %{message_payloads: message_payloads})
    {:noreply, socket}
  end

  def handle_in("seen", %{"ids" => message_ids}, socket) do
    current_company_id = Guardian.Phoenix.Socket.current_resource(socket).company_id
    Enum.each(message_ids, &(&1) |> Messages.get_message!() |> maybe_update_message(current_company_id))
    {:noreply, socket}
  end

  def handle_in("send", %{"auctionId" => auction_id, "recipient" => recipient_company_id, "content" => content}, socket) do
    current_user = Guardian.Phoenix.Socket.current_resource(socket)
    {:ok, _message} = Messages.create_message(%{
      auction_id: auction_id,
      author_company_id: current_user.company_id,
      author_id: current_user.id,
      content: content,
      has_been_seen: false,
      recipient_company_id: recipient_company_id
    })
    Enum.each([current_user.company_id, recipient_company_id], &send(self(), {:messages_update, &1}))
    {:noreply, socket}
  end

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
  defp authorized?(socket, id, token) do
    authed = Guardian.Phoenix.Socket.authenticate(socket, Oceanconnect.Guardian, token)

    case authed do
      {:ok, authed_socket} ->
        company_id = Guardian.Phoenix.Socket.current_resource(authed_socket).company_id
        if company_id == String.to_integer(id), do: authed_socket, else: false

      {:error, _reason} ->
        false
    end
  end

  defp maybe_update_message(%Message{recipient_company_id: current_company_id} = message, current_company_id), do:
    Messages.update_message(message, %{has_been_seen: true})
  defp maybe_update_message(_message, _current_company_id), do: nil
end
