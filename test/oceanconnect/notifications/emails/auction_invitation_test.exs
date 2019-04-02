defmodule Oceanconnect.Notifications.Emails.AuctionInvitationTest do
  use Oceanconnect.DataCase
  alias Oceanconnect.Notifications.Emails
  alias Oceanconnect.Accounts
  alias Oceanconnect.Auctions

  alias Oceanconnect.Auctions.{
    Solution,
    TermAuction
  }

  alias Oceanconnect.Auctions.AuctionStore.{
    AuctionState,
    TermAuctionState
  }

  describe "spot auctions" do
    setup do
      buyer_company = insert(:company)
      buyers = insert_list(2, :user, company: buyer_company)
      supplier_companies = insert_list(2, :company, is_supplier: true)
      Enum.each(supplier_companies, &insert(:user, company: &1))
      suppliers = Accounts.users_for_companies(supplier_companies)

      [vessel1, vessel2] = insert_list(2, :vessel)
      [fuel1, fuel2] = insert_list(2, :fuel)

      auction =
        :auction
        |> insert(
          buyer: buyer_company,
          suppliers: supplier_companies,
          auction_vessel_fuels: [
            build(:vessel_fuel, vessel: vessel1, fuel: fuel1, quantity: 200),
            build(:vessel_fuel, vessel: vessel2, fuel: fuel2, quantity: 200)
          ]
        )

      vessel_name_list =
        [vessel1, vessel2]
        |> Enum.map(& &1.name)
        |> Enum.join(", ")

      auction_state = Auctions.get_auction_state!(auction)

      created_event =
        Oceanconnect.Auctions.AuctionEvent.auction_created(auction, hd(buyers))
        |> Oceanconnect.Auctions.AuctionEventStore.persist()

      {:ok,
       %{
         auction_state: auction_state,
         buyers: buyers,
         suppliers: suppliers,
         supplier_companies: supplier_companies,
         vessels: [vessel1, vessel2],
         vessel_name_list: vessel_name_list
       }}
    end

    test "auction invitation email builds for all suppliers",
         %{
           auction_state: auction_state,
           buyers: buyers,
           suppliers: suppliers,
           vessel_name_list: vessel_name_list
         } do
      auction = Auctions.get_auction!(auction_state.auction_id)
      emails = Emails.AuctionInvitation.generate(auction_state)
      sent_to_ids = Enum.map(emails, fn email -> email.to.id end)
      supplier_ids = Enum.map(suppliers, & &1.id)
      buyer_ids = Enum.map(buyers, & &1.id)

      assert Enum.all?(supplier_ids, &(&1 in sent_to_ids))
      refute Enum.any?(buyer_ids, &(&1 in sent_to_ids))

      auction_type =
        case auction.type do
          "spot" -> ""
          "formula_related" -> "Formula-Related "
          "forward-fixed" -> "Forward-Fixed "
        end

      for supplier_email <- emails do
        assert supplier_email.subject ==
                 "You have been invited to #{auction_type}Auction #{auction.id} for #{
                   vessel_name_list
                 } at #{auction.port.name}"

        assert supplier_email.html_body =~ Integer.to_string(auction.id)
      end
    end
  end

  describe "term auctions" do
    setup do
      buyer_company = insert(:company)
      buyers = insert_list(2, :user, company: buyer_company)
      supplier_companies = insert_list(2, :company, is_supplier: true)
      Enum.each(supplier_companies, &insert(:user, company: &1))
      suppliers = Accounts.users_for_companies(supplier_companies)

      [vessel1, vessel2] = insert_list(2, :vessel)
      fuel = insert(:fuel)

      auction =
        :term_auction
        |> insert(
          buyer: buyer_company,
          suppliers: supplier_companies
        )

      auction_state = Auctions.get_auction_state!(auction)

      created_event =
        Oceanconnect.Auctions.AuctionEvent.auction_created(auction, hd(buyers))
        |> Oceanconnect.Auctions.AuctionEventStore.persist()

      {:ok,
       %{
         auction_state: auction_state,
         buyers: buyers,
         suppliers: suppliers
       }}
    end

    test "auction invitation email builds for all suppliers",
         %{
           auction_state: auction_state,
           buyers: buyers,
           suppliers: suppliers
         } do
      emails = Emails.AuctionInvitation.generate(auction_state)
      sent_to_ids = Enum.map(emails, fn email -> email.to.id end)
      buyer_ids = Enum.map(buyers, & &1.id)
      supplier_ids = Enum.map(suppliers, & &1.id)
      auction = Auctions.get_auction!(auction_state.auction_id)

      assert Enum.all?(supplier_ids, &(&1 in sent_to_ids))
      refute Enum.any?(buyer_ids, &(&1 in sent_to_ids))

      for supplier_email <- emails do
        assert supplier_email.subject ==
                 "You have been invited to Auction #{auction.id} at #{auction.port.name}"

        assert supplier_email.html_body =~ Integer.to_string(auction.id)
      end
    end
  end
end
