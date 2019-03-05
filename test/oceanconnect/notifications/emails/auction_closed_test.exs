defmodule Oceanconnect.Notifications.Emails.AuctionClosedTest do
  alias Oceanconnect.Notifications.Emails.{AuctionClosed}
  alias Oceanconnect.Accounts
  alias Oceanconnect.Auctions

  setup do
    credit_company = insert(:company, name: "Ocean Connect Marine", is_broker: true)
    buyer_company = insert(:company)
    buyers = insert_list(2, :user, company: buyer_company)

    supplier_companies = insert_list(2, :company, is_supplier: true)
    Enum.each(supplier_companies, & insert(:user, company: &1))
    suppliers = Accounts.users_for_companies(supplier_companies)

    barges = insert_list(2, :barge)

    spot_auction =
      :auction
      |> insert(
        buyer: buyer_company,
        suppliers: supplier_companies
      )

    term_auction =
      :term_auction
      |> insert(
        buyer: buyer_company,
        suppliers: supplier_companies
      )

    spot_auction_state = %{auction_id: spot_auction.id, winning_solution: solution, submitted_barges: barges}
    term_auction_state = %{auction_id: term_auction.id, winning_soltuion: solution,submitted_barges: barges}
  end

  test "auction closed email builds for winning suppliers and buyer who participated in a spot auction", %{buyers: buyers, suppliers: suppliers, spot_auction: spot_auction} do
    active_users = buyers ++ suppliers

    emails = AuctionClosed.generate(auction_state)
  end

  test "auction closed email builds for winning suppliers and buyer who participated in a term auction", %{buyers: buyers, suppliers: suppliers, term_auction: term_auction} do
    active_users = buyers ++ suppliers

    emails = AuctionClosed.generate(auction_state)
  end
end
