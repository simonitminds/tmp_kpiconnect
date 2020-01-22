defmodule OceanconnectWeb.Api.FileIOController do
  use OceanconnectWeb, :controller
  import Oceanconnect.Auctions.Guards

  alias Oceanconnect.Accounts
  alias Oceanconnect.Accounts.{Company, User}
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{AuctionPayload, AuctionSuppliers, AuctionSupplierCOQ}
  alias OceanconnectWeb.FileIO

  @extension_whitelist ~w(jpg jpeg gif png pdf)

  def upload_coq(
        conn,
        %{"auction_id" => auction_id, "fuel_id" => fuel_id, "supplier_id" => supplier_id}
      ) do
    with user = %User{} <- OceanconnectWeb.Plugs.Auth.current_user(conn),
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
end
