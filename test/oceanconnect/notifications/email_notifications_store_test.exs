defmodule Oceanconnect.Notifications.EmailNotificationStoreTest do
  use Oceanconnect.DataCase
  use Bamboo.Test, shared: true

  alias Oceanconnect.Notifications.{EmailNotificationStore, Emails}
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{AuctionEvent, EventNotifier, AuctionStore.AuctionState}

  describe "email notifications store" do
    setup do
      vessels =
        insert_list(2, :vessel)
      port = insert(:port)
      port_name = port.name
      buyer_company = insert(:company)
      buyer = insert(:user, company: buyer_company)

      vessel_name_list =
        vessels
        |> Enum.map(& &1.name)
        |> Enum.join(", ")

      auction =
        insert(:auction, buyer: buyer_company, vessels: vessels, port: port)

      {:ok, %{auction: auction, vessel_name_list: vessel_name_list, port_name: port_name, buyer: buyer}}
    end

    test "auction created event produces email", %{auction: auction, vessel_name_list: vessel_name_list, port_name: port_name} do
      auction_state = AuctionState.from_auction(auction)

      AuctionEvent.auction_created(auction, nil)
      |> EventNotifier.broadcast(auction_state)

      emails = Emails.AuctionInvitation.generate(auction_state)

      for email <- emails do
        assert_email_delivered_with(subject: "You have been invited to Auction #{auction.id} for #{vessel_name_list} at #{port_name}")
      end
    end

    test "auction rescheduled event produces email", %{auction: auction, vessel_name_list: vessel_name_list, port_name: port_name, buyer: buyer} do
      new_start_time =
        DateTime.utc_now()
        |> DateTime.to_unix()
        |> Kernel.+(60)
        |> DateTime.from_unix!()

      {:ok, auction} = Auctions.update_auction(auction, %{scheduled_start: new_start_time}, buyer)
      auction_state = AuctionState.from_auction(auction)

      emails = Emails.AuctionInvitation.generate(auction_state)

      for email <- emails do
        assert_email_delivered_with(subject: "The start time for Auction #{auction.id} for #{vessel_name_list} at #{port_name} has been changed")
      end
    end
  end
end
