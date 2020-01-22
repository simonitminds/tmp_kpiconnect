defmodule OceanconnectWeb.FileIOController do
  use OceanconnectWeb, :controller
  import Oceanconnect.Auctions.Guards

  alias Oceanconnect.Accounts.User
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.AuctionSupplierCOQ
  alias OceanconnectWeb.FileIO

  @extension_whitelist ~w(jpg jpeg gif png pdf)

  def view_coq(conn, %{"id" => auction_supplier_coq_id}) do
    with auction_supplier_coq = %AuctionSupplierCOQ{file_extension: file_extension} <-
           Auctions.get_auction_supplier_coq(auction_supplier_coq_id),
         %{body: coq} <- FileIO.get(auction_supplier_coq) do
      conn
      |> put_resp_content_type(MIME.type(file_extension))
      |> send_resp(200, coq)
    else
      _ -> conn
    end
  end
end
