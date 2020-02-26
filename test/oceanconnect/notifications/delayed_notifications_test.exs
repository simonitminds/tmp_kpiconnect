defmodule Oceanconnect.Notifications.DelayedNotificationsTest do
  use Oceanconnect.DataCase
  use Bamboo.Test, shared: true

  alias Oceanconnect.Auctions
  alias Oceanconnect.Accounts
  alias Oceanconnect.Notifications.Emails

  alias Oceanconnect.Auctions.{
    AuctionEvent,
    EventNotifier,
    AuctionStore.AuctionState,
    AuctionSupervisor
  }

  @email_config Application.get_env(:oceanconnect, :emails, %{
                  auction_starting_soon_offset: 2_000,
                  delivered_coq_reminder_offset: 2_000
                })

  setup do
    {:ok, _pid} = Oceanconnect.Notifications.NotificationsSupervisor.start_link()
    :ok
  end

  describe "auction starting soon notification" do
    setup do
      buyer_company = insert(:company)
      buyers = insert_list(2, :user, company: buyer_company)
      supplier_companies = insert_list(2, :company, is_supplier: true)
      Enum.each(supplier_companies, &insert(:user, company: &1))
      suppliers = Accounts.users_for_companies(supplier_companies)

      start_time =
        DateTime.utc_now()
        |> DateTime.to_unix(:millisecond)
        |> Kernel.+(@email_config.auction_starting_soon_offset + 1_000)
        |> DateTime.from_unix!(:millisecond)

      port = insert(:port)

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

    test "auction creation with start time greater than the offset will not immediately send upcoming notification",
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

    test "upcoming auction start notification is sent when within the offset time",
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

      :timer.sleep(1_000)

      for email <- emails do
        assert_delivered_email(email)
      end
    end

    test "rescheduling an auction with start time greater than the offset doesn't immediately send upcoming notification",
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
        |> DateTime.to_unix(:millisecond)
        |> Kernel.+(@email_config.auction_starting_soon_offset + 1_500)
        |> DateTime.from_unix!(:millisecond)

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

    test "upcoming auction start notification is sent when within the recheduled offset time",
         %{
           auction_attrs: auction_attrs,
           vessel_fuels: vessel_fuels,
           buyer_company: buyer_company,
           buyers: buyers
         } do
      {:ok, auction} = Auctions.create_auction(auction_attrs, hd(buyers))
      auction = %{auction | auction_vessel_fuels: vessel_fuels, buyer: buyer_company}
      {:ok, pid} = Oceanconnect.Auctions.AuctionStoreStarter.start_link()

      new_start_time =
        DateTime.utc_now()
        |> DateTime.to_unix(:millisecond)
        |> Kernel.+(@email_config.auction_starting_soon_offset + 1_500)
        |> DateTime.from_unix!(:millisecond)

      {:ok, auction} =
        Auctions.update_auction(auction, %{"scheduled_start" => new_start_time}, hd(buyers))

      :timer.sleep(500)

      auction_state = AuctionState.from_auction(auction)

      AuctionEvent.auction_created(auction, hd(buyers))
      |> EventNotifier.broadcast(auction_state)

      emails = Emails.AuctionStartingSoon.generate(auction_state)

      :timer.sleep(1_500)

      for email <- emails do
        assert_delivered_email(email)
      end
    end
  end
end
