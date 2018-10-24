defmodule OceanconnectWeb.ChatfishChannel do
  use OceanconnectWeb, :channel

  def join("user_messaging:" <> id, payload, socket) do
    IO.inspect "HERE"
    if authorized?(socket, id, payload) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
    # case authenticated_company(socket, params) do
    #   {:ok, company_id} ->
    #     send(self, {:list_auctions})
    #     {:ok, assign(socket, :company_id, company_id)}
    #
    #   {:error, _reason} ->
    #     {:error, %{reason: "could not load company id"}}
    # end
  end

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

  def handle_info({:list_auctions}, socket) do
    company_id = socket.assigns[:company_id]
    push socket, "auction_list", %{auctions: get_auctions_for_company(company_id)}
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
  defp authenticated_company(socket, %{"token" => token}) do
    authed = Guardian.Phoenix.Socket.authenticate(socket, Oceanconnect.Guardian, token)

    case authed do
      {:ok, authed_socket} ->
        {:ok, Guardian.Phoenix.Socket.current_resource(authed_socket).company_id}

      {:error, reason} -> {:error, reason}
    end
  end
  defp authenticated?(_, _), do: {:error, "token not supplied"}

  defp get_auctions_for_company(company_id) do
    company_id
    |> Oceanconnect.Auctions.list_participating_auctions()
    |> Enum.map(fn auction ->
      auction
      |> Oceanconnect.Auctions.fully_loaded()
      |> Oceanconnect.Auctions.AuctionPayload.get_auction_payload!(company_id)
    end)
  end
end
