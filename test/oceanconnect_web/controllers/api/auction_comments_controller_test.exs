defmodule OceanconnectWeb.Api.AuctionCommentsControllerTest do
  use OceanconnectWeb.ConnCase
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.AuctionComment

  setup do
    supplier_company = insert(:company, is_supplier: true)
    supplier = insert(:user, company: supplier_company)

    auction =
      insert(:term_auction, suppliers: [supplier_company])
      |> Auctions.fully_loaded()

    {:ok, _pid} =
      start_supervised(
        {Oceanconnect.Auctions.AuctionSupervisor,
         {auction,
          %{
            exclude_children: [
              :auction_reminder_timer,
              :auction_event_handler,
              :auction_scheduler
            ]
          }}}
      )

    authed_conn = OceanconnectWeb.Plugs.Auth.api_login(build_conn(), supplier)

    {:ok, conn: authed_conn, auction: auction, supplier: supplier}
  end

  describe "submit" do
    test "supplier can submit a comment", %{auction: auction, conn: conn} do
      response =
        post(conn, "/api/auctions/#{auction.id}/comments", %{
          auction_id: auction.id,
          comment: "Hi"
        })

      assert json_response(response, 200) == %{
               "success" => true,
               "message" => "Comment created successfully"
             }
    end

    test "supplier can delete a comment", %{auction: auction, conn: conn, supplier: supplier} do
      comment = %AuctionComment{
        id: UUID.uuid4(:hex),
        auction_id: auction.id,
        supplier_id: supplier.id,
        comment: "Hi"
      }

      response =
        delete(conn, "/api/auctions/#{auction.id}/comments/#{comment.id}", %{
          auction_id: auction.id,
          comment_id: comment.id
        })

      assert json_response(response, 200) == %{
               "success" => true,
               "message" => "Comment deleted successfully"
             }
    end
  end
end
