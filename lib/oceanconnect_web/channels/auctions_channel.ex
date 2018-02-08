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
  defp authorized?(socket = %Phoenix.Socket{assigns: %{current_user: current_user_id}}, id, %{"token" => token}) do
    case Phoenix.Token.verify(socket, "user socket", token, max_age: 1209600) do
      {:ok, user_id} ->
        if current_user_id = user_id = String.to_integer(id) do
          true
        else
          false
        end
      {:error, _reason} ->
        false
    end
  end
  defp authorized?(_,_,_), do: false
end
