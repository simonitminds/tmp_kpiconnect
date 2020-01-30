defmodule OceanconnectWeb.Api.FileIOController do
  use OceanconnectWeb, :controller
  import Oceanconnect.Auctions.Guards

  alias Oceanconnect.Accounts
  alias Oceanconnect.Accounts.{Company, User}
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{AuctionPayload, AuctionSuppliers, AuctionSupplierCOQ}
  alias OceanconnectWeb.FileIO

  @extension_whitelist ~w(jpg jpeg gif png pdf)

  def delete_coq(conn, %{"id" => auction_supplier_coq_id}) do
    with user = %User{} <- OceanconnectWeb.Plugs.Auth.current_user(conn),
         auction_supplier_coq = %AuctionSupplierCOQ{
           auction_id: auction_id,
           supplier_id: supplier_id
         } <-
           Auctions.get_auction_supplier_coq(auction_supplier_coq_id),
         true <- is_authorized_to_change?(auction_id, user, supplier_id),
         %AuctionSupplierCOQ{} <- FileIO.delete(auction_supplier_coq),
         {:ok, _} <- Auctions.delete_auction_supplier_coq(auction_supplier_coq) do
      auction_payload =
        auction_id
        |> Auctions.get_auction!()
        |> AuctionPayload.get_auction_payload!(supplier_id)

      conn
      |> render("submit.json", auction_payload: auction_payload)
    else
      _ ->
        conn
        |> put_status(422)
        |> render("show.json", %{success: false, message: "Invalid"})
    end
  end

  def upload_coq(
        conn,
        %{"auction_id" => auction_id, "fuel_id" => fuel_id, "supplier_id" => supplier_id}
      ) do
    with user = %User{} <- OceanconnectWeb.Plugs.Auth.current_user(conn),
         true <- is_authorized_to_change?(auction_id, user, String.to_integer(supplier_id)),
         {:ok, coq_binary, _conn} <- Plug.Conn.read_body(conn),
         {:ok, file_extension} <- get_file_extension(conn),
         %AuctionSupplierCOQ{} <-
           Auctions.store_auction_supplier_coq(
             auction_id,
             supplier_id,
             fuel_id,
             coq_binary,
             file_extension
           ) do
      auction_payload =
        auction_id
        |> Auctions.get_auction!()
        |> AuctionPayload.get_auction_payload!(supplier_id)

      conn
      |> render("submit.json", auction_payload: auction_payload)
    else
      {:file_error, message} ->
        conn
        |> put_status(404)
        |> render("show.json", %{success: false, message: message})

      _ ->
        conn
        |> put_status(422)
        |> render("show.json", %{success: false, message: "Invalid"})
    end
  end

  defp get_file_extension(conn) do
    file_extension =
      conn
      |> Plug.Conn.get_req_header("content-type")
      |> List.first()
      |> MIME.extensions()
      |> List.first()

    if file_extension in @extension_whitelist,
      do: {:ok, file_extension},
      else: {:file_error, "Incorrect file type."}
  end

  defp is_authorized_to_change?(_auction_id, %User{is_admin: true}, _supplier_id), do: true

  defp is_authorized_to_change?(auction_id, %User{company_id: supplier_id}, supplier_id),
    do: Auctions.get_auction_status!(auction_id) in [:pending, :open]

  defp is_authorized_to_change?(_auction_id, _user, _supplier_id), do: false
end
