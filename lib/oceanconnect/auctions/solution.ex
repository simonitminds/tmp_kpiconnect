defmodule Oceanconnect.Auctions.Solution do
  alias Oceanconnect.Auctions.Auction

  defstruct valid: false,
            auction_id: nil,
            bids: [],
            normalized_price: nil,
            total_price: nil,
            latest_time_entered: nil,
            latest_original_time_entered: nil,
            comment: nil

  def from_bids(bids, product_bids, %Auction{id: auction_id, auction_vessel_fuels: vessel_fuels}) do
    product_ids = Map.keys(product_bids)

    product_quantities =
      product_bids
      |> Enum.reduce(%{}, fn {product_id, _bids}, acc ->
        total_quantity =
          vessel_fuels
          |> Enum.filter(fn vf -> "#{vf.fuel_id}" == product_id end)
          |> Enum.reduce(0, fn vf, acc -> acc + vf.quantity end)

        Map.put(acc, product_id, total_quantity)
      end)

    %__MODULE__{
      auction_id: auction_id,
      bids: Enum.sort_by(bids, & &1.fuel_id),
      valid: is_valid?(bids, product_ids),
      normalized_price: normalized_price(bids, product_quantities),
      total_price: total_price(bids, product_quantities),
      latest_time_entered: latest_time_entered(bids),
      latest_original_time_entered: latest_original_time_entered(bids)
    }
  end

  def sort_tuple(solution) do
    # Sorting by `valid` first ensures that invalid/incomplete solutions are considered last.
    valid_indicator = if solution.valid, do: 0, else: 1

    latest_original_time_entered =
      if solution.latest_original_time_entered do
        DateTime.to_unix(solution.latest_original_time_entered, :microsecond)
      else
        DateTime.utc_now()
      end

    {valid_indicator, solution.total_price, latest_original_time_entered}
  end

  defp is_valid?(bids, product_ids) do
    Enum.all?(product_ids, fn product_id ->
      Enum.any?(bids, fn bid -> "#{bid.fuel_id}" == product_id end)
    end)
  end

  defp latest_time_entered([]), do: nil

  defp latest_time_entered(bids) do
    bids
    |> Enum.map(& &1.time_entered)
    |> Enum.sort(&(DateTime.compare(&1, &2) == :gt))
    |> hd()
  end

  defp latest_original_time_entered([]), do: nil

  defp latest_original_time_entered(bids) do
    bids
    |> Enum.map(& &1.original_time_entered)
    |> Enum.sort(&(DateTime.compare(&1, &2) == :gt))
    |> hd()
  end

  defp normalized_price(bids, product_quantities) do
    {total_price, total_quantity} =
      Enum.reduce(bids, {0, 0}, fn bid, acc = {total_price, total_quantity} ->
        if quantity = Map.get(product_quantities, "#{bid.fuel_id}") do
          total_quantity = total_quantity + quantity
          total_price = total_price + bid.amount * quantity
          {total_price, total_quantity}
        else
          acc
        end
      end)

    total_price / total_quantity
  end

  defp total_price(bids, product_quantities) do
    Enum.reduce(bids, 0, fn bid, acc ->
      quantity = product_quantities["#{bid.fuel_id}"]
      acc + bid.amount * quantity
    end)
  end
end
