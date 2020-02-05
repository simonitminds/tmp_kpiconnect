defmodule Oceanconnect.FakeIO do
  alias Oceanconnect.Auctions.AuctionSupplierCOQ

  def delete(auction_supplier_coq = %AuctionSupplierCOQ{}), do: auction_supplier_coq
  def get(%AuctionSupplierCOQ{}), do: %{body: "test"}
  def upload(auction_supplier_coq = %AuctionSupplierCOQ{}, _binary), do: auction_supplier_coq
  def upload(_auction_supplier_coq, _binary), do: :error
end
