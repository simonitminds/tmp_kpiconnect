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

    port =
      insert(:port, companies: [buyer_company] ++ supplier_companies)

    auction_params = %{
      anonymous_bidding: false,
      port: port,
      terminal: 10,
      starting_month: _,
      ending_month: valid_start_time,
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

  end
end
