defmodule OceanconnectWeb.FileIOController do
  use OceanconnectWeb, :controller

  alias Oceanconnect.Accounts.User
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.AuctionSupplierCOQ
  alias OceanconnectWeb.FileIO

  def view_coq(conn, %{"id" => auction_supplier_coq_id}) do
    with user = %User{} <- OceanconnectWeb.Plugs.Auth.current_user(conn),
         auction_supplier_coq = %AuctionSupplierCOQ{
           auction_id: auction_id,
           file_extension: file_extension,
           supplier_id: supplier_id
         } <-
           Auctions.get_auction_supplier_coq(auction_supplier_coq_id),
         true <- is_authorized_to_view?(auction_id, user, supplier_id),
         %{body: coq} <- FileIO.get(auction_supplier_coq) do
      conn
      |> put_resp_content_type(MIME.type(file_extension))
      |> send_resp(200, coq)
    else
      _ -> send_resp(conn, 401, "Not Authorized")
    end
  end

  defp is_authorized_to_view?(_auction_id, %User{is_admin: true}, _supplier_id), do: true

  defp is_authorized_to_view?(_auction_id, %User{company_id: supplier_id}, supplier_id), do: true

  defp is_authorized_to_view?(auction_id, %User{company_id: buyer_id}, _supplier_id),
    do: auction_id |> Auctions.get_auction!() |> Map.get(:buyer_id) == buyer_id

  defp is_authorized_to_view?(_auction_id, _user, _supplier_id), do: false
end
