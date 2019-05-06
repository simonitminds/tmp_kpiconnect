defmodule Oceanconnect.Admin.FuelIndex.IndexTest do
  use Oceanconnect.FeatureCase
  alias Oceanconnect.Repo
  alias Oceanconnect.Admin.FuelIndex.IndexPage
  alias Oceanconnect.Auctions.FuelIndex

  hound_session()

  setup do
    admin_user = insert(:user, %{is_admin: true})
    user = insert(:user)
    insert_list(20, :fuel_index)

    {fuel_index_page1, fuel_index_page2} =
      FuelIndex.alphabetical()
      |> Repo.all()
      |> Enum.split(10)

    {:ok,
     admin_user: admin_user,
     user: user,
     fuel_index_page1: fuel_index_page1,
     fuel_index_page2: fuel_index_page2}
  end

  describe "fuel index entries" do
    test "renders the company index page for admins", %{
      admin_user: admin_user,
      fuel_index_page1: fuel_index_page1
    } do
      login_user(admin_user)
      IndexPage.visit()
      assert IndexPage.is_current_path?()
      assert IndexPage.has_fuel_index_entries?(fuel_index_page1)
    end

    test "company index page does not render for regular fuels", %{user: user} do
      login_user(user)
      IndexPage.visit()
      refute IndexPage.is_current_path?()
    end

    test "admin can deactivate a fuel grade", %{
      admin_user: admin_user,
      fuel_index_page1: fuel_index_page1
    } do
      login_user(admin_user)
      IndexPage.visit()
      assert IndexPage.is_current_path?()
      assert IndexPage.has_fuel_index_entries?(fuel_index_page1)

      fuel = hd(fuel_index_page1)
      IndexPage.deactivate_fuel_index(fuel)
      assert IndexPage.is_fuel_index_inactive?(fuel)
    end

    test "admin can activate a fuel grade", %{
      admin_user: admin_user,
      fuel_index_page1: fuel_index_page1
    } do
      login_user(admin_user)
      IndexPage.visit()
      assert IndexPage.is_current_path?()
      assert IndexPage.has_fuel_index_entries?(fuel_index_page1)

      fuel = hd(fuel_index_page1)
      IndexPage.deactivate_fuel_index(fuel)
      assert IndexPage.is_fuel_index_active?(fuel)
    end

    test "admin can navigate in pagination", %{
      admin_user: admin_user,
      fuel_index_page1: fuel_index_page1,
      fuel_index_page2: fuel_index_page2
    } do
      login_user(admin_user)
      IndexPage.visit()
      assert IndexPage.is_current_path?()
      assert IndexPage.has_fuel_index_entries?(fuel_index_page1)

      IndexPage.next_page()
      :timer.sleep(200)
      assert IndexPage.has_fuel_index_entries?(fuel_index_page2)

      IndexPage.previous_page()
      assert IndexPage.has_fuel_index_entries?(fuel_index_page1)
    end
  end
end
