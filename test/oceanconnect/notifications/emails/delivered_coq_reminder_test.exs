defmodule Oceanconnect.Notifications.Emails.DeliveredCOQReminderTest do
  use Oceanconnect.DataCase
  alias Oceanconnect.Notifications.Emails.DeliveredCOQReminder
  alias Oceanconnect.Accounts
  alias Oceanconnect.Auctions

  alias Oceanconnect.Auctions.{AuctionStore.AuctionState, Solution}

  describe "Spot Auctions" do
    setup do
      supplier_companies = [sc1, _sc2, sc3] = insert_list(3, :company, is_supplier: true)
      Enum.each(supplier_companies, &insert(:user, company: &1))
      winning_suppliers = Accounts.users_for_companies([sc1, sc3])

      [vessel1, vessel2] = insert_list(2, :vessel)
      [fuel1, fuel2, fuel3] = insert_list(3, :fuel)

      auction =
        :auction
        |> insert(
          suppliers: supplier_companies,
          auction_vessel_fuels: [
            build(:vessel_fuel, vessel: vessel1, fuel: fuel1, quantity: 200),
            build(:vessel_fuel, vessel: vessel2, fuel: fuel2, quantity: 200),
            build(:vessel_fuel, vessel: vessel2, fuel: fuel3, quantity: 400)
          ]
        )

      [avf1, avf2, avf3] = auction.auction_vessel_fuels

      solution_bids = [
        create_bid(200.00, nil, sc1.id, "#{avf1.id}", auction, true),
        create_bid(220.00, nil, sc3.id, "#{avf2.id}", auction, false),
        create_bid(250.00, nil, sc3.id, "#{avf3.id}", auction, false)
      ]

      %AuctionState{product_bids: product_bids} = Auctions.get_auction_state!(auction)

      winning_solution = Solution.from_bids(solution_bids, product_bids, auction)

      # Create fixtures
      insert(:auction_fixture, auction: auction, fuel: fuel1, vessel: vessel1, supplier: sc1)
      insert(:auction_fixture, auction: auction, fuel: fuel2, vessel: vessel2, supplier: sc3)
      insert(:auction_fixture, auction: auction, fuel: fuel3, vessel: vessel2, supplier: sc3)

      {:ok, _fixtures} =
        close_auction!(auction)
        |> Auctions.create_fixtures_from_state()

      {:ok,
       %{
         auction: auction,
         fuels: [fuel1, fuel2, fuel3],
         supplier_companies: supplier_companies,
         winning_solution: winning_solution,
         winning_suppliers: winning_suppliers
       }}
    end

    test "delivered coq reminder email builds for winning suppliers",
         %{
           auction: auction,
           fuels: [fuel1, fuel2, fuel3],
           supplier_companies: [sc1, _sc2, _sc3],
           winning_solution: winning_solution,
           winning_suppliers: winning_suppliers
         } do
      emails = DeliveredCOQReminder.generate(auction.id, winning_solution)
      sent_to_ids = Enum.map(emails, fn email -> email.to.id end)
      winning_supplier_ids = Enum.map(winning_suppliers, & &1.id)

      assert Enum.all?(winning_supplier_ids, &(&1 in sent_to_ids))

      for email <- emails do
        assert email.subject ==
                 "The e.t.a. Auction #{auction.id} at #{auction.port.name} is approaching."

        assert email.html_body =~
                 "Please go to the below link to upload your COQ"

        if email.to.company_id == sc1.id do
          assert email.html_body =~ fuel1.name
          Enum.all?([fuel2, fuel3], &refute(email.html_body =~ &1.name))
        else
          Enum.all?([fuel2, fuel3], &assert(email.html_body =~ &1.name))
          refute email.html_body =~ fuel1.name
        end
      end
    end
  end
end
