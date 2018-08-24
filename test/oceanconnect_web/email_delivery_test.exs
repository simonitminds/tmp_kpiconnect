defmodule OceanconnectWeb.EmailDeliveryTest do
  use Oceanconnect.DataCase
  use Bamboo.Test

  alias OceanconnectWeb.Email
  alias OceanconnectWeb.Mailer
  alias Oceanconnect.Accounts

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

  describe "sending emails" do
    test "sends auction invitation emails to all invited suppliers", %{auction: auction} do
      emails = Email.auction_invitation(auction)
      for email <- emails do
        Mailer.deliver_now(email)
        assert_delivered_email email
      end
    end

    test "sends auction starting soon emails to all participants", %{auction: auction} do
      %{supplier_emails: supplier_emails, buyer_emails: buyer_emails} = Email.auction_starting_soon(auction)
      for email <- List.flatten([supplier_emails | buyer_emails]) do
        Mailer.deliver_now(email)
      end
    end

    test "sends auction completion emails to winning supplier and buyer", %{auction: auction, winning_supplier_company: winning_supplier_company} do
      %{supplier_emails: supplier_emails, buyer_emails: buyer_emails} = Email.auction_closed(100, 20000, winning_supplier_company, auction)
      for supplier_email <- supplier_emails do
        Mailer.deliver_now(supplier_email)
        assert_delivered_email supplier_email
      end
      for buyer_email <- buyer_emails do
        Mailer.deliver_now(buyer_email)
        assert_delivered_email buyer_email
      end
    end

    test "sends action cancellation emails to all participants", %{auction: auction} do
      %{supplier_emails: supplier_emails, buyer_emails: buyer_emails} = Email.auction_canceled(auction)
      for supplier_email <- supplier_emails do
        Mailer.deliver_now(supplier_email)
        assert_delivered_email supplier_email
      end
      for buyer_email <- buyer_emails do
        Mailer.deliver_now(buyer_email)
        assert_delivered_email buyer_email
      end
    end
  end
end
