defmodule Oceanconnect.Auctions.Solution do
  alias Oceanconnect.Auctions.Auction

  defstruct valid: false,
    bids: [],
    normalized_price: nil,
    total_price: nil,
    latest_time_entered: nil,
    comment: nil

  def from_bids(bids, product_bids, %Auction{auction_vessel_fuels: vessel_fuels}) do
    product_ids = Map.keys(product_bids)
    product_quantities = product_bids
    |> Enum.reduce(%{}, fn({product_id, _bids}, acc) ->
      total_quantity = vessel_fuels
      |> Enum.filter(fn(vf) -> "#{vf.fuel_id}" == product_id end)
      |> Enum.reduce(0, fn(vf, acc) -> acc + vf.quantity end)
      Map.put(acc, product_id, total_quantity)
    end)

    %__MODULE__{
      bids: Enum.sort_by(bids, &(&1.fuel_id)),
      valid: is_valid?(bids, product_ids),
      normalized_price: normalized_price(bids, product_quantities),
      total_price: total_price(bids, product_quantities),
      latest_time_entered: latest_time_entered(bids)
    }
  end

  def is_valid?(bids, product_ids) do
    Enum.all?(product_ids, fn(product_id) ->
      Enum.any?(bids, fn(bid) -> "#{bid.fuel_id}" == product_id end)
    end)
  end

  defp latest_time_entered([]), do: nil
  defp latest_time_entered(bids) do
    bids
    |> Enum.map(&(&1.time_entered))
    |> Enum.sort(&(DateTime.compare(&2, &1) == :gt))
    |> hd()
  end

  defp normalized_price(bids, product_quantities) do
    total_price = total_price(bids, product_quantities)
    total_quantity = product_quantities
    |> Map.values()
    |> Enum.sum()

    try do
      total_price / total_quantity
    rescue
      _ -> nil
    end
  end

  defp total_price(bids, product_quantities) do
    Enum.reduce(bids, 0, fn(bid, acc) ->
      quantity = product_quantities["#{bid.fuel_id}"]
      acc + (bid.amount * quantity)
    end)
  end

  def less_equal(s1, s2) do
    s1.total_price <= s2.total_price &&
      DateTime.compare(s1.latest_time_entered, s2.latest_time_entered) != :gt
  end
end
