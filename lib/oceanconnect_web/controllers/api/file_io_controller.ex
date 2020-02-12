defmodule OceanconnectWeb.Api.FileIOController do
  use OceanconnectWeb, :controller
  import Oceanconnect.Auctions.Guards

  alias Oceanconnect.Accounts.User
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{AuctionNotifier, AuctionPayload, AuctionSupplierCOQ}

  @file_io Application.get_env(:oceanconnect, :file_io, OceanconnectWeb.FileIO)
  @extension_whitelist ~w(jpg jpeg gif png pdf)

  def delete_coq(conn, %{"id" => auction_supplier_coq_id}) do
    with user = %User{company_id: company_id} <- OceanconnectWeb.Plugs.Auth.current_user(conn),
         auction_supplier_coq = %AuctionSupplierCOQ{
           supplier_id: supplier_id,
           delivered: delivered
         } <- Auctions.get_auction_supplier_coq(auction_supplier_coq_id),
         auction_id <- get_auction_id(auction_supplier_coq),
         auction = %struct{} when is_auction(struct) <- Auctions.get_auction!(auction_id),
         true <- is_authorized_to_change?(auction, user, set_params(supplier_id, delivered)),
         %AuctionSupplierCOQ{} <- @file_io.delete(auction_supplier_coq),
         {:ok, _} <- Auctions.delete_auction_supplier_coq(auction_supplier_coq) do
      auction = Auctions.get_auction!(auction_id)
      AuctionNotifier.notify_participants(auction)

      conn
      |> render("submit.json",
        auction_payload: AuctionPayload.get_auction_payload!(auction, company_id)
      )
    else
      _ ->
        conn
        |> put_status(422)
        |> render("show.json", %{success: false, message: "Invalid"})
    end
  end

  def upload_coq(conn, params = %{"auction_id" => auction_id}) do
    with user = %User{company_id: company_id} <- OceanconnectWeb.Plugs.Auth.current_user(conn),
         auction = %struct{} when is_auction(struct) <- Auctions.get_auction!(auction_id),
         true <- is_authorized_to_change?(auction, user, params),
         {:ok, coq_binary, _conn} <- Plug.Conn.read_body(conn, length: 25_000_000),
         {:ok, file_extension} <- get_file_extension(conn),
         %AuctionSupplierCOQ{} <-
           params
           |> Map.merge(%{"coq_binary" => coq_binary, "file_extension" => file_extension})
           |> Auctions.store_auction_supplier_coq(auction) do
      updated_auction = Auctions.fully_loaded(auction, true)
      AuctionNotifier.notify_participants(updated_auction)

      conn
      |> render("submit.json",
        auction_payload: AuctionPayload.get_auction_payload!(updated_auction, company_id)
      )
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

  defp get_auction_id(%AuctionSupplierCOQ{auction_id: auction_id, term_auction_id: nil}),
    do: auction_id

  defp get_auction_id(%AuctionSupplierCOQ{term_auction_id: term_auction_id}), do: term_auction_id

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

  defp is_authorized_to_change?(%{finalized: false}, _user, %{"delivered" => _}), do: false
  defp is_authorized_to_change?(_auction, %User{is_admin: true}, _params), do: true

  defp is_authorized_to_change?(auction, user, params = %{"supplier_id" => supplier_id})
       when is_bitstring(supplier_id),
       do:
         is_authorized_to_change?(
           auction,
           user,
           Map.merge(params, %{
             "supplier_id" => String.to_integer(supplier_id)
           })
         )

  defp is_authorized_to_change?(%{finalized: true}, %User{company_id: supplier_id}, %{
         "supplier_id" => supplier_id,
         "delivered" => _
       }),
       do: true

  defp is_authorized_to_change?(%{finalized: true}, %User{company_id: supplier_id}, %{
         "supplier_id" => supplier_id
       }),
       do: false

  defp is_authorized_to_change?(%{id: auction_id}, %User{company_id: supplier_id}, %{
         "supplier_id" => supplier_id
       }),
       do: Auctions.get_auction_status!(auction_id) in [:pending, :open]

  defp is_authorized_to_change?(_auction, _user, _params), do: false

  defp set_params(supplier_id, true), do: %{"supplier_id" => supplier_id, "delivered" => true}
  defp set_params(supplier_id, _), do: %{"supplier_id" => supplier_id}
end
