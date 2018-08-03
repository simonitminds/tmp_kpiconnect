defmodule Oceanconnect.AdminTest do
  use Oceanconnect.FeatureCase
  alias Oceanconnect.Auctions
  alias Oceanconnect.AdminPage

  hound_session()

  setup do
    admin_company = insert(:company)
    admin = insert(:user, company: admin_company, is_admin: true)
    buyer_company = insert(:company)
    buyer = insert(:user, company: buyer_company)
    supplier_company = insert(:company, is_supplier: true)
    supplier_company2 = insert(:company, is_supplier: true)
    supplier = insert(:user, company: supplier_company)

    auction =
      insert(
        :auction,
        buyer: buyer_company,
        suppliers: [supplier_company, supplier_company2],
        duration: 600_000
      )

    {:ok, _pid} =
      start_supervised(
        {Oceanconnect.Auctions.AuctionSupervisor,
         {auction, %{exclude_children: [:auction_scheduler]}}}
      )

    {:ok, %{admin: admin, auction: auction, buyer: buyer, supplier: supplier}}
  end

  test "impersonating a buyer as an admin", %{admin: admin, buyer: buyer} do
    login_user(admin)
    AdminPage.impersonate_user(buyer)
    assert AdminPage.logged_as() == buyer.name
  end
end
