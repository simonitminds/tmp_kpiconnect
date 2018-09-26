defmodule OceanconnectWeb.EmailDeliveryTest do
  use Oceanconnect.DataCase
  use Bamboo.Test

  alias OceanconnectWeb.Email
  alias OceanconnectWeb.Mailer
  alias Oceanconnect.Accounts
  alias Oceanconnect.Auctions

  setup do
    buyer_company = insert(:company, is_supplier: false)
    credit_company = insert(:company, name: "Ocean Connect Marine")

    supplier_companies = [
      insert(:company, is_supplier: true),
      insert(:company, is_supplier: true)
    ]

    auction =
      insert(:auction, buyer: buyer_company, suppliers: supplier_companies)
      |> Auctions.fully_loaded()

    winning_supplier_company = Enum.at(Enum.take_random(auction.suppliers, 1), 0)

    {:ok, %{auction: auction, winning_supplier_company: winning_supplier_company}}
  end

  describe "sending emails" do
    test "sends auction invitation emails to all invited suppliers", %{auction: auction} do
      emails = Email.auction_invitation(auction)

      for email <- emails do
        Mailer.deliver_now(email)
        assert_delivered_email(email)
      end
    end

    test "sends auction starting soon emails to all participants", %{auction: auction} do
      %{supplier_emails: supplier_emails, buyer_emails: buyer_emails} =
        Email.auction_starting_soon(auction)

      for email <- List.flatten([supplier_emails | buyer_emails]) do
        Mailer.deliver_now(email)
      end
    end

    test "sends auction completion emails to winning supplier and buyer", %{
      auction: auction,
      winning_supplier_company: winning_supplier_company
    } do
      is_traded_bid = true

      %{supplier_emails: supplier_emails, buyer_emails: buyer_emails} =
        Email.auction_closed(100, 20000, winning_supplier_company, auction, is_traded_bid)

      for supplier_email <- supplier_emails do
        Mailer.deliver_now(supplier_email)
        assert_delivered_email(supplier_email)
      end

      for buyer_email <- buyer_emails do
        Mailer.deliver_now(buyer_email)
        assert_delivered_email(buyer_email)
      end
    end

    test "sends action cancellation emails to all participants", %{auction: auction} do
      %{supplier_emails: supplier_emails, buyer_emails: buyer_emails} =
        Email.auction_canceled(auction)

      for supplier_email <- supplier_emails do
        Mailer.deliver_now(supplier_email)
        assert_delivered_email(supplier_email)
      end

      for buyer_email <- buyer_emails do
        Mailer.deliver_now(buyer_email)
        assert_delivered_email(buyer_email)
      end
    end
  end
end
