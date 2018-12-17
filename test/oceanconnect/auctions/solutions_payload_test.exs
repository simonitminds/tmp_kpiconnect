defmodule Oceanconnect.Auctions.SolutionsPayloadTest do
  use Oceanconnect.DataCase

  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{Auction, Solution, AuctionPayload, AuctionSupervisor}

  setup do
    buyer_company = insert(:company, name: "FooCompany")
    supplier = insert(:company, name: "BarCompany")
    supplier2 = insert(:company, name: "BazCompany")
    supplier3 = insert(:company, name: "BooCompany")
    supplier4 = insert(:company, name: "FazCompany")

    [vessel1, vessel2]  = insert_list(2, :vessel)
    [fuel1, fuel2]      = insert_list(2, :fuel)

    auction =
      insert(:auction,
        buyer: buyer_company,
        suppliers: [supplier, supplier2, supplier3, supplier4],
        auction_vessel_fuels: [
          build(:vessel_fuel, vessel: vessel1, fuel: fuel1),
          build(:vessel_fuel, vessel: vessel1, fuel: fuel2),
          build(:vessel_fuel, vessel: vessel2, fuel: fuel1),
          build(:vessel_fuel, vessel: vessel2, fuel: fuel2)
        ]
      )
      |> Auctions.fully_loaded()

    {:ok, _pid} =
      start_supervised(
        {AuctionSupervisor,
         {auction, %{exclude_children: [:auction_reminder_timer, :auction_scheduler]}}}
      )

    Auctions.start_auction(auction)
    :timer.sleep(500)

    {:ok,
     %{
       auction: auction,
       buyer: buyer_company,
       supplier: supplier,
       supplier2: supplier2,
       supplier3: supplier3,
       supplier4: supplier4,
       vessel_fuels: auction.auction_vessel_fuels
     }}
  end

  describe "other_solutions" do
    test "prioritizes valid solutions over all others", %{auction: auction, buyer: buyer, supplier: supplier1, supplier2: supplier2, supplier3: supplier3, supplier4: supplier4, vessel_fuels: vessel_fuels} do
      [vf1, vf2, vf3, vf4 | _] = vessel_fuels

      create_bid(10.00, nil, supplier1.id, vf1.id, auction)
      |> Auctions.place_bid()
      create_bid(10.00, nil, supplier1.id, vf2.id, auction)
      |> Auctions.place_bid()
      create_bid(20.00, nil, supplier1.id, vf3.id, auction)
      |> Auctions.place_bid()
      create_bid(20.00, nil, supplier1.id, vf4.id, auction)
      |> Auctions.place_bid()

      create_bid(5.00, nil, supplier2.id, vf1.id, auction)
      |> Auctions.place_bid()
      create_bid(5.00, nil, supplier2.id, vf2.id, auction)
      |> Auctions.place_bid()

      create_bid(20.00, nil, supplier3.id, vf1.id, auction)
      |> Auctions.place_bid()
      create_bid(20.00, nil, supplier3.id, vf2.id, auction)
      |> Auctions.place_bid()
      create_bid(30.00, nil, supplier3.id, vf3.id, auction)
      |> Auctions.place_bid()
      create_bid(30.00, nil, supplier3.id, vf4.id, auction)
      |> Auctions.place_bid()


      auction_payload =
        auction
        |> AuctionPayload.get_auction_payload!(buyer.id)

      %{
        other_solutions: other_solutions
      } = auction_payload.solutions

      assert [true, false] = Enum.map(other_solutions, &(&1.valid))
    end
  end
end
