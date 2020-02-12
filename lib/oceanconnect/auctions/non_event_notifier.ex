defmodule Oceanconnect.Auctions.NonEventNotifier do
  import Oceanconnect.Auctions.Guards

  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{AuctionCache, AuctionEvent, AuctionSupplierCOQ, Command}

  def emit(:error, _), do: :error

  def emit(auction_supplier_coq = %AuctionSupplierCOQ{delivered: true}, :coq_uploaded) do
    react_to(auction_supplier_coq)
    broadcast(:delivered_coq_uploaded, auction_supplier_coq)
    auction_supplier_coq
  end

  def emit({:ok, auction_supplier_coq = %AuctionSupplierCOQ{}}) do
    react_to(auction_supplier_coq)
    {:ok, true}
  end

  def emit(auction_supplier_coq = %AuctionSupplierCOQ{}, _) do
    react_to(auction_supplier_coq)
    auction_supplier_coq
  end

  def emit(:error), do: :error

  def broadcast(type, data) do
    :ok =
      Phoenix.PubSub.broadcast(:auction_pubsub, "auctions", {:non_event_notification, type, data})
  end

  def react_to(%AuctionSupplierCOQ{auction_id: auction_id}),
    do: auction_id |> Auctions.get_auction!() |> Auctions.fully_loaded(true) |> update_cache()

  defp update_cache(auction = %struct{}) when is_auction(struct) do
    auction
    |> Command.update_cache()
    |> AuctionCache.process_command()
  end
end
