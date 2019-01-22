defmodule Oceanconnect.TermAuctionNewTest do
  use Oceanconnect.FeatureCase
  alias Oceanconnect.{AuctionNewPage, AuctionShowPage}

  hound_session()

  setup do
    buyer_company = insert(:company, credit_margin_amount: 5.40)
    buyer = insert(:user, company: buyer_company)

    login_user(buyer)

    fuels = insert_list(2, :fuel)
    buyer_vessels = insert_list(3, :vessel, company: buyer_company)
    supplier_companies = insert_list(3, :company, is_supplier: true)

    selected_company1 = Enum.at(supplier_companies, 0)
    selected_company2 = Enum.at(supplier_companies, 1)

    port =
      insert(:port, companies: [buyer_company] ++ supplier_companies)

    valid_start_time =
      DateTime.utc_now()
      |> DateTime.to_unix()
      |> Kernel.+(100_000)
      |> DateTime.from_unix!()

    auction_params = %{
      anonymous_bidding: false,
      port: port,
      terminal: "AA",
      start_month: valid_start_time,
      end_month: valid_start_time,
      scheduled_start_time: valid_start_time,
      suppliers: [
        %{
          id: selected_company1.id
        },
        %{
          id: selected_company2.id
        }
      ]
    }

    {:ok,
      %{
        buyer: buyer,
        buyer_vessels: buyer_vessels,
        params: auction_params,
        buyer_company: buyer_company,
        suppliers: supplier_companies,
        port: port,
        fuels: fuels
      }
    }
  end

  describe "creating a forward-fixed term auction" do
    test "visiting the new auction page" do
      AuctionNewPage.visit()
      AuctionNewPage.select_auction_type(:forward_fixed)

      assert AuctionNewPage.has_fields?([
        "type",
        "terminal",
        "additional_information",
        "anonymous_bidding",
        "scheduled_start",
        "term_start_date",
        "term_end_date",
        "is_traded_bid_allowed",
        "po",
        "port_id",
        "select-fuel",
        "select-port",
        "select-vessel"
      ])
    end
  end
end
