defmodule OceanconnectWeb.UserSocket do
  use Phoenix.Socket

  ## Channels
  channel("user_auctions:*", OceanconnectWeb.AuctionsChannel)

  ## Transports
  transport(:websocket, Phoenix.Transports.WebSocket)
  # transport :longpoll, Phoenix.Transports.LongPoll

  # Socket params are passed from the client and can
  # be used to verify and authenticate a user. After
  # verification, you can put default assigns into
  # the socket that will be set for all channels, ie
  #
  #     {:ok, assign(socket, :user_id, verified_user_id)}
  #
  # To deny connection, return `:error`.
  #
  # See `Phoenix.Token` documentation for examples in
  # performing token verification on connect.
  def connect(%{"token" => token}, socket) do
    # max_age: 1209600 is equivalent to two weeks in seconds
    auth = Guardian.Phoenix.Socket.authenticate(socket, Oceanconnect.Guardian, token)

    case auth do
      {:ok, authed_socket} ->
        {:ok, authed_socket}

      {:error, _reason} ->
        :error
    end
  end

  def connect(_, socket), do: socket
  # Socket id's are topics that allow you to identify all sockets for a given user:
  #

  def id(socket), do: "user_socket:#{Guardian.Phoenix.Socket.current_resource(socket).id}"

  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     OceanconnectWeb.Endpoint.broadcast("user_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  # def id(_socket), do: nil
end
