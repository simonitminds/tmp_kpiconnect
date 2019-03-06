defmodule Oceanconnect.Notifications.Emails.AuctionClosedTest do
  use Oceanconnect.DataCase
  alias Oceanconnect.Notifications.Emails.{AuctionClosed}
  alias Oceanconnect.Accounts
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{AuctionStore.AuctionState, Solution}

  setup do
    credit_company = insert(:company, name: "Ocean Connect Marine", is_broker: true)
    buyer_company = insert(:company)
    buyers = insert_list(2, :user, company: buyer_company)

    supplier_companies = insert_list(2, :company, is_supplier: true)
    Enum.each(supplier_companies, &insert(:user, company: &1))
    suppliers = Accounts.users_for_companies(supplier_companies)
    [winning_supplier_company] = Enum.take_random(supplier_companies, 1)
    winning_suppliers = Accounts.users_for_companies([winning_supplier_company])

    barges = insert_list(2, :barge)
    [vessel1, vessel2] = insert_list(2, :vessel)
    [fuel1, fuel2] = insert_list(2, :fuel)
    [barge1, barge2] = insert_list(2, :barge)

    vessel_fuels = insert_list(2, :vessel_fuel)

    auction =
      :auction
      |> insert(
        buyer: buyer_company,
        suppliers: supplier_companies,
        auction_vessel_fuels: [
          build(:vessel_fuel, vessel: vessel1, fuel: fuel1, quantity: 200),
          build(:vessel_fuel, vessel: vessel2, fuel: fuel2, quantity: 200)
        ]
      )

    approved_barges = [
      insert(:auction_barge,
        auction: auction,
        barge: barge1,
        supplier: hd(supplier_companies),
        approval_status: "APPROVED"
      ),
      insert(:auction_barge,
        auction: auction,
        barge: barge2,
        supplier: List.last(supplier_companies),
        approval_status: "APPROVED"
      )
    ]

    solution_bids = [
      create_bid(
        200.00,
        nil,
        hd(supplier_companies).id,
        "#{hd(auction.auction_vessel_fuels).id}",
        auction,
        true
      ),
      create_bid(
        220.00,
        nil,
        List.last(supplier_companies).id,
        "#{hd(auction.auction_vessel_fuels).id}",
        auction,
        false
      )
    ]

    auction_state =
      %AuctionState{product_bids: product_bids} = Auctions.get_auction_state!(auction)

    winning_solution = Solution.from_bids(solution_bids, product_bids, auction)

    auction_state =
      auction_state
      |> Map.merge(%{winning_solution: winning_solution, submitted_barges: approved_barges})

    {:ok,
     %{
       auction_state: auction_state,
       buyers: buyers,
       suppliers: suppliers,
       supplier_companies: supplier_companies
     }}
  end

  test "auction closed email builds for winning suppliers and buyer who participated in a spot auction", %{auction_state: auction_state} do
    emails = AuctionClosed.generate(auction_state)
  end

  test "auction closed email builds for winning suppliers and buyer who participated in a term auction",
       %{buyers: buyers, suppliers: suppliers, term_auction: term_auction} do
    active_users = buyers ++ suppliers
  end
end
