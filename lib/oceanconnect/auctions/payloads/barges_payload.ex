defmodule Oceanconnect.Auctions.Payloads.BargesPayload do
  alias Oceanconnect.Auctions.{AuctionBarge, Barge}

  def get_barges_payload!(submitted_barges, supplier: supplier_id) do
    submitted_barges
    |> Enum.filter(&(&1.supplier_id == supplier_id))
    |> Enum.map(&scrub_barge_for_supplier(&1, supplier_id))
  end

  def get_barges_payload!(submitted_barges, buyer: buyer_id) do
    submitted_barges
    |> Enum.map(&scrub_barge_for_buyer(&1, buyer_id))
  end

  defp scrub_barge_for_supplier(
         auction_barge = %AuctionBarge{barge: barge = %Barge{port: port}},
         _supplier_id
       ) do
    scrubbed_barge =
      %{barge | port: port.name}
      |> Map.delete(:port_id)

    %{auction_barge | barge: scrubbed_barge}
  end

  defp scrub_barge_for_buyer(
         auction_barge = %AuctionBarge{barge: barge = %Barge{port: port}},
         _buyer_id
       ) do
    scrubbed_barge =
      %{barge | port: port.name}
      |> Map.delete(:port_id)

    %{auction_barge | barge: scrubbed_barge}
  end
end
