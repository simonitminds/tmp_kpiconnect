defmodule Oceanconnect.Auctions.AuctionNotifierTest do
  use Oceanconnect.DataCase
  use Bamboo.Test

  alias Oceanconnect.Accounts
  alias Oceanconnect.Auctions.AuctionNotifier

  setup do
    auction = insert(:auction)
		buyer_company = Accounts.get_company!(auction.buyer_id)
		[insert(:user, company: buyer_company), insert(:user, company: buyer_company)]

		Enum.each(auction.suppliers, fn(supplier_company) ->
			insert(:user, %{company: supplier_company})
		end)
    winning_supplier_company = Enum.at(Enum.take_random(auction.suppliers, 1), 0)

    {:ok, %{auction: auction, winning_supplier_company: winning_supplier_company}}
  end

  describe "auction notifier delivers emails" do
    test "auction notifier sends invitation emails to all invited suppliers", %{auction: auction} do
      assert {:ok, emails} = AuctionNotifier.notify_auction_created(auction)
      assert length(emails) > 0
      for email <- emails do
        assert_delivered_email email
      end
    end

    test "auction notifier sends upcoming emails to participants", %{auction: auction} do
      assert {:ok, emails} = AuctionNotifier.notify_auction_upcoming(auction)
      assert length(emails) > 0
      for email <- emails do
        assert_delivered_email email
      end
    end

    test "auction notifier sends cancellation emails to participants", %{auction: auction} do
      assert {:ok, emails} = AuctionNotifier.notify_auction_canceled(auction)
      assert length(emails) > 0
      for email <- emails do
        assert_delivered_email email
      end
    end

    test "auction notifier sends completion emails to winning supplier and buyer", %{winning_supplier_company: winning_supplier_company, auction: auction} do
      assert {:ok, emails} = AuctionNotifier.notify_auction_completed(winning_supplier_company.id, auction.id)
      assert length(emails) > 0
      for email <- emails do
        assert_delivered_email email
      end
    end
  end
end
