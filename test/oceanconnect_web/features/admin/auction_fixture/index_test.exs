defmodule Oceanconnect.Admin.AuctionFixture.IndexTest do
  use Oceanconnect.FeatureCase
  alias Oceanconnect.{AuctionShowPage, AdminPage}
  alias Oceanconnect.Admin, as: Admin
  alias Oceanconnect.Admin.Fixture.{IndexPage, EditPage}

  alias Oceanconnect.Auctions

  hound_session()

  setup do
    [auction: auction1, fixtures: fixtures1] = create_auction_with_fixtures()
    [auction: auction2, fixtures: fixtures2] = create_auction_with_fixtures()
    fixtures = fixtures1 ++ fixtures2

    {:ok,
     %{
       auction: auction1,
       fixtures: fixtures
     }}
  end

  describe "admin" do
    setup do
      admin_user = insert(:user, is_admin: true)
      login_user(admin_user)
      :ok
    end

    test "can navigate to the fixture index from the admin panel" do
      AdminPage.visit()
      AdminPage.select_menu_item(:auction_fixtures)
      assert Admin.Fixture.IndexPage.is_current_path?()
    end

    test "can see a list of fixtures grouped by auction", %{fixtures: fixtures} do
      Admin.Fixture.IndexPage.visit()

      for fixture <- fixtures do
        assert Admin.Fixture.IndexPage.has_fixture?(fixture)
      end
    end

    test "can delete a fixture", %{fixtures: fixtures} do
      Admin.Fixture.IndexPage.visit()

      for fixture <- fixtures do
        assert Admin.Fixture.IndexPage.has_fixture?(fixture)
      end

      [fixture | fixtures] = fixtures

      IndexPage.edit_fixture(fixture.id)
      EditPage.delete_fixture()

      refute IndexPage.has_fixture?(fixture)

      for fixture <- fixtures do
        assert Admin.Fixture.IndexPage.has_fixture?(fixture)
      end
    end
  end

  defp create_auction_with_fixtures do
    buyer_company = insert(:company)
    insert(:user, company: buyer_company)

    supplier_company = insert(:company, is_supplier: true)
    insert(:user, company: supplier_company)

    auction =
      insert(
        :auction,
        buyer: buyer_company,
        suppliers: [supplier_company],
        finalized: true
      )

    auction_state = close_auction!(auction)
    {:ok, auction_fixtures} = Auctions.create_fixtures_from_state(auction_state)
    [auction: auction, fixtures: auction_fixtures]
  end
end
