defmodule Oceanconnect.Notifications.DelayedNotificationsTest do
  use Oceanconnect.DataCase
  use Bamboo.Test, shared: true

  alias Oceanconnect.Auctions
  alias Oceanconnect.Accounts
  alias Oceanconnect.Notifications.{Emails}

  alias Oceanconnect.Auctions.{
    AuctionEvent,
    AuctionSupervisor,
    EventNotifier,
    AuctionStore.AuctionState
  }

  setup do
    buyer_company = insert(:company)
    buyers = insert_list(2, :user, company: buyer_company)
    supplier_companies = insert_list(2, :company, is_supplier: true)
    Enum.each(supplier_companies, &insert(:user, company: &1))
    suppliers = Accounts.users_for_companies(supplier_companies)

    start_time =
      DateTime.utc_now()
      |> DateTime.to_unix(:second)
      |> Kernel.+(4_000)
      |> DateTime.from_unix!(:second)

    port = insert(:port)
    fuel = insert(:fuel)

    auction_attrs = %{
      "port_id" => port.id,
      "type" => "spot",
      "scheduled_start" => start_time,
      "suppliers" => supplier_companies,
      "buyer_id" => buyer_company.id
    }

    vessel_fuels = insert_list(2, :vessel_fuel)

    {:ok,
     %{
       auction_attrs: auction_attrs,
       buyers: buyers,
       vessel_fuels: vessel_fuels,
       buyer_company: buyer_company
     }}
  end

  describe "auction starting soon notification" do
    test "auction creation with start over an hour in the future doesn't send upcoming notification",
         %{
           auction_attrs: auction_attrs,
           buyers: buyers,
           vessel_fuels: vessel_fuels,
           buyer_company: buyer_company
         } do
      {:ok, auction} = Auctions.create_auction(auction_attrs, hd(buyers))
      auction = %{auction | auction_vessel_fuels: vessel_fuels, buyer: buyer_company}
      auction_state = AuctionState.from_auction(auction)

      emails = Emails.AuctionStartingSoon.generate(auction_state)

      :timer.sleep(500)

      for email <- emails do
        refute_delivered_email(email)
      end
    end

    test "rescheduling an creation with start time greater than an hour from now doesn't trigger upcoming auction emails",
         %{
           auction_attrs: auction_attrs,
           vessel_fuels: vessel_fuels,
           buyer_company: buyer_company,
           buyers: buyers
         } do
      {:ok, auction} = Auctions.create_auction(auction_attrs, hd(buyers))
      auction = %{auction | auction_vessel_fuels: vessel_fuels, buyer: buyer_company}

      new_start_time =
        DateTime.utc_now()
        |> DateTime.to_unix(:second)
        # add number of seconds > hour
        |> Kernel.+(4_000)
        |> DateTime.from_unix!(:second)

      {:ok, auction} =
        Auctions.update_auction(auction, %{"scheduled_start" => new_start_time}, hd(buyers))

      auction_state = AuctionState.from_auction(auction)

      AuctionEvent.auction_created(auction, hd(buyers))
      |> EventNotifier.broadcast(auction_state)

      emails = Emails.AuctionStartingSoon.generate(auction_state)

      :timer.sleep(500)

      for email <- emails do
        refute_delivered_email(email)
      end
    end
  end
end
