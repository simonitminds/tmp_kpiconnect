defmodule OceanconnectWeb.FileIO do
  alias Oceanconnect.Auctions.{AuctionSuppliers, AuctionSupplierCOQ}

  @bucket_name Application.get_env(:ex_aws, :bucket, nil)

  def delete(auction_supplier_coq = %AuctionSupplierCOQ{}) do
    if @bucket_name,
      do: delete_from_s3(auction_supplier_coq),
      else: delete_from_local(auction_supplier_coq)
  end

  defp delete_from_local(auction_supplier_coq) do
    dir = storage_dir(auction_supplier_coq)
    file_name = file_name(auction_supplier_coq)
    File.rm!("#{storage_dir(auction_supplier_coq)}#{file_name}")
    auction_supplier_coq
  end

  defp delete_from_s3(auction_supplier_coq) do
    @bucket_name
    |> ExAws.S3.delete_object(
      "#{storage_dir(auction_supplier_coq)}#{file_name(auction_supplier_coq)}"
    )
    |> ExAws.request!()

    auction_supplier_coq
  end

  def get(auction_supplier_coq = %AuctionSupplierCOQ{}) do
    if @bucket_name,
      do: get_from_s3(auction_supplier_coq),
      else: get_from_local(auction_supplier_coq)
  end

  defp get_from_local(auction_supplier_coq) do
    dir = storage_dir(auction_supplier_coq)
    file_name = file_name(auction_supplier_coq)
    File.read!("#{storage_dir(auction_supplier_coq)}#{file_name}")
  end

  defp get_from_s3(auction_supplier_coq) do
    @bucket_name
    |> ExAws.S3.get_object(
      "#{storage_dir(auction_supplier_coq)}#{file_name(auction_supplier_coq)}"
    )
    |> ExAws.request!()
  end

  def upload(auction_supplier_coq = %AuctionSupplierCOQ{}, coq_binary) do
    if @bucket_name,
      do: upload_to_s3(auction_supplier_coq, coq_binary),
      else: upload_to_local(auction_supplier_coq, coq_binary)
  end

  def upload(_auction_supplier_coq, _coq_binary), do: :error

  defp upload_to_local(auction_supplier_coq, coq_binary) do
    dir = storage_dir(auction_supplier_coq)
    file_name = file_name(auction_supplier_coq)
    File.mkdir_p!(dir)
    File.write!("#{storage_dir(auction_supplier_coq)}#{file_name}", coq_binary)
    auction_supplier_coq
  end

  defp upload_to_s3(auction_supplier_coq, coq_binary) do
    @bucket_name
    |> ExAws.S3.put_object(
      "#{storage_dir(auction_supplier_coq)}#{file_name(auction_supplier_coq)}",
      coq_binary
    )
    |> ExAws.request!()

    auction_supplier_coq
  end

  defp file_name(%AuctionSupplierCOQ{
         supplier_id: supplier_id,
         fuel_id: fuel_id,
         file_extension: file_extension
       }) do
    "#{supplier_id}-#{fuel_id}.#{file_extension}"
  end

  defp storage_dir(%AuctionSupplierCOQ{auction_id: nil, term_auction_id: auction_id}) do
    "/uploads/#{auction_id}/coqs/"
  end

  defp storage_dir(%AuctionSupplierCOQ{auction_id: auction_id}) do
    "/uploads/#{auction_id}/coqs/"
  end
end
