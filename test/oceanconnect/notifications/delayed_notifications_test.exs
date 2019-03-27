defmodule Oceanconnect.Notifications.DelayedNotificationsTest do
  use Oceanconnect.DataCase
  alias Oceanconnect.Auctions
  alias Oceanconnect.Accounts

  alias Oceanconnect.Notifications.DelayedNotificationsSupervisor
  alias Oceanconnect.Auctions.{AuctionEvent, AuctionSupervisor}

  setup do
    buyer_company = insert(:company)
    buyers = insert_list(2, :user, company: buyer_company)
    supplier_companies = insert_list(2, :company, is_supplier: true)
    Enum.each(supplier_companies, &insert(:user, company: &1))
    suppliers = Accounts.users_for_companies(supplier_companies)

    [vessel1, vessel2] = insert_list(2, :vessel)
    [fuel1, fuel2] = insert_list(2, :fuel)

    start_time =
      DateTime.utc_now()
      |> DateTime.to_unix(:second)
      |> Kernel.+(60)
      |> DateTime.from_unix!(:second)

    auction =
      :auction
      |> insert(
        buyer: buyer_company,
        suppliers: supplier_companies,
        auction_vessel_fuels: [
          build(:vessel_fuel, vessel: vessel1, fuel: fuel1, quantity: 200),
          build(:vessel_fuel, vessel: vessel2, fuel: fuel2, quantity: 200)
        ],
        scheduled_start: start_time
      )


    {:ok, %{auction: auction, buyers: buyers}}
  end

  test "auction creation triggers upcoming auction emails", %{auction: auction, buyers: buyers} do
    auction_id = auction.id

    assert :ok = Phoenix.PubSub.subscribe(:auction_pubsub, "auction:#{auction_id}:upcoming_reminder")

    created_event =
      Oceanconnect.Auctions.AuctionEvent.auction_created(auction, hd(buyers))
      |> Oceanconnect.Auctions.AuctionEventStore.persist()
  end
end
