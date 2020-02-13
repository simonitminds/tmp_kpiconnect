defmodule Oceanconnect.Auctions.NonEventNotifier do
  import Oceanconnect.Auctions.Guards

  alias Oceanconnect.Accounts.User
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{AuctionCache, AuctionEvent, AuctionSupplierCOQ, Command}

  def emit(:error, _), do: :error

  def emit(auction_supplier_coq = %AuctionSupplierCOQ{delivered: true}) do
    react_to(auction_supplier_coq)
    broadcast(:delivered_coq_uploaded, auction_supplier_coq)
    auction_supplier_coq
  end

  def emit(auction_supplier_coq = %AuctionSupplierCOQ{}) do
    react_to(auction_supplier_coq)
    auction_supplier_coq
  end

  def emit({:ok, auction_supplier_coq = %AuctionSupplierCOQ{}}) do
    react_to(auction_supplier_coq)
    {:ok, true}
  end

  def emit(user = %User{has_2fa: true}, one_time_pass) do
    broadcast(:two_factor_auth, %{user: user, one_time_pass: one_time_pass})
  end

  def emit(user = %User{}, token) do
    broadcast(:password_reset, %{user: user, token: token})
  end

  def emit(:user_interest, new_user_info) do
    broadcast(:user_interest, new_user_info)
  end

  def emit(:error), do: :error

  def broadcast(type, data) do
    :ok =
      Phoenix.PubSub.broadcast(:auction_pubsub, "auctions", {:non_event_notification, type, data})
  end

  def react_to(%AuctionSupplierCOQ{auction_id: nil, term_auction_id: auction_id}),
    do: auction_id |> Auctions.get_auction!() |> Auctions.fully_loaded(true) |> update_cache()

  def react_to(%AuctionSupplierCOQ{auction_id: auction_id}),
    do: auction_id |> Auctions.get_auction!() |> Auctions.fully_loaded(true) |> update_cache()

  defp update_cache(auction = %struct{}) when is_auction(struct) do
    auction
    |> Command.update_cache()
    |> AuctionCache.process_command()
  end
end
