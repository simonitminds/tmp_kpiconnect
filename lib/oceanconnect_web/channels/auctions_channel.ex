defmodule OceanconnectWeb.AuctionsChannel do
  use OceanconnectWeb, :channel

  def join("user_auctions:" <> id, payload, socket) do
    if authorized?(socket, id, payload) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
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
  defp authorized?(socket = %Phoenix.Socket{id: current_user_socket}, id, %{"token" => token}) do
    case Guardian.Phoenix.Socket.authenticate(socket, Oceanconnect.Guardian, token) do
      {:ok, authed_socket} ->
        if current_user_socket == "user_socket:#{id}" do
          true
        else
          false
        end
      {:error, _reason} -> false
    end
  end
  defp authorized?(_,_,_), do: false
end
