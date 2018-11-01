defmodule OceanconnectWeb.ChatfishChannel do
  use OceanconnectWeb, :channel

  alias Oceanconnect.Messages.MessagePayload

  def join("user_messages:" <> id, payload, socket) do
    if authorized?(socket, id, payload) do
      send(self(), {:messages_update, String.to_integer(id)})
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_info({:messages_update, company_id}, socket) do
    message_payloads = MessagePayload.get_message_payloads_for_company(company_id)
    broadcast! socket, "messages_update", %{message_payloads: message_payloads}
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
