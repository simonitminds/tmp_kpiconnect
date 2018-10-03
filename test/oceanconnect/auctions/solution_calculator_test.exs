defmodule Oceanconnect.Auctions.SolutionCalculatorTest do
  use Oceanconnect.DataCase
  alias Oceanconnect.Auctions.AuctionStore.AuctionState
  alias Oceanconnect.Auctions.SolutionCalculator
  alias Oceanconnect.Auctions.{Auction, AuctionBid, Fuel}

  setup do
    supplier_company = insert(:company)
    supplier2_company = insert(:company)
    supplier3_company = insert(:company)

    auction = insert(:auction, auction_vessel_fuels: [build(:vessel_fuel), build(:vessel_fuel)])
    vessel_fuels = auction.auction_vessel_fuels

    [fuel1, fuel2] = Enum.map(vessel_fuels, &(&1.fuel))

    {:ok,
     %{
        auction: auction,
        fuel1: fuel1,
        fuel2: fuel2,
        supplier1: supplier_company,
        supplier2: supplier2_company,
        supplier3: supplier3_company
     }}
  end

  describe "process" do
    test "determines best overall bid combination from lowest bids", %{
      auction: auction = %Auction{id: auction_id},
      fuel1: %Fuel{id: fuel1_id},
      fuel2: %Fuel{id: fuel2_id},
      supplier1: %{id: supplier1_id},
      supplier2: %{id: supplier2_id},
      supplier3: %{id: supplier3_id},
    } do
      fuel1_supplier1 = %AuctionBid{amount: 2.00, supplier_id: supplier1_id, auction_id: auction_id, fuel_id: fuel1_id, active: true}
      fuel1_supplier2 = %AuctionBid{amount: 2.50, supplier_id: supplier2_id, auction_id: auction_id, fuel_id: fuel1_id, active: true}
      fuel2_supplier2 = %AuctionBid{amount: 3.00, supplier_id: supplier3_id, auction_id: auction_id, fuel_id: fuel2_id, active: true}

      current_state = %AuctionState{
        auction_id: auction_id,
        status: :open,
        product_bids: %{
          "#{fuel1_id}" => %{
            lowest_bids: [fuel1_supplier1, fuel1_supplier2]
          },
          "#{fuel2_id}" => %{
            lowest_bids: [fuel2_supplier2]
          }
        }
      }

      %{solutions: %{best_overall: solution}} = SolutionCalculator.process(current_state, auction)

      assert %{
        valid: true,
        bids: [^fuel1_supplier1, ^fuel2_supplier2]
      } = solution
    end

    test "determines the best offer for each supplier", %{
      auction: auction = %Auction{id: auction_id},
      fuel1: %Fuel{id: fuel1_id},
      fuel2: %Fuel{id: fuel2_id},
      supplier1: %{id: supplier1_id},
      supplier2: %{id: supplier2_id},
      supplier3: %{id: _supplier3_id},
    } do
      fuel1_supplier1 = %AuctionBid{amount: 2.00, supplier_id: supplier1_id, auction_id: auction_id, fuel_id: fuel1_id, active: true}
      fuel1_supplier2 = %AuctionBid{amount: 2.50, supplier_id: supplier2_id, auction_id: auction_id, fuel_id: fuel1_id, active: true}
      fuel2_supplier1 = %AuctionBid{amount: 3.00, supplier_id: supplier1_id, auction_id: auction_id, fuel_id: fuel2_id, active: true}

      current_state = %AuctionState{
        auction_id: auction_id,
        status: :open,
        product_bids: %{
          "#{fuel1_id}" => %{
            lowest_bids: [fuel1_supplier1, fuel1_supplier2]
          },
          "#{fuel2_id}" => %{
            lowest_bids: [fuel2_supplier1]
          }
        }
      }

      %{solutions: %{best_by_supplier: supplier_solutions}} = SolutionCalculator.process(current_state, auction)

      assert %{
        ^supplier1_id => %{
          valid: true,
          bids: [^fuel1_supplier1, ^fuel2_supplier1]
        },
        ^supplier2_id => %{
          valid: false,
          bids: [^fuel1_supplier2]
        }
      } = supplier_solutions
    end

    test "determines the best single supplier solution", %{
      auction: auction = %Auction{id: auction_id},
      fuel1: %Fuel{id: fuel1_id},
      fuel2: %Fuel{id: fuel2_id},
      supplier1: %{id: supplier1_id},
      supplier2: %{id: supplier2_id},
      supplier3: %{id: _supplier3_id},
    } do
      fuel1_supplier1 = %AuctionBid{amount: 2.00, supplier_id: supplier1_id, auction_id: auction_id, fuel_id: fuel1_id, active: true}
      fuel2_supplier1 = %AuctionBid{amount: 3.00, supplier_id: supplier1_id, auction_id: auction_id, fuel_id: fuel2_id, active: true}
      fuel1_supplier2 = %AuctionBid{amount: 2.50, supplier_id: supplier2_id, auction_id: auction_id, fuel_id: fuel1_id, active: true}
      fuel2_supplier2 = %AuctionBid{amount: 2.00, supplier_id: supplier2_id, auction_id: auction_id, fuel_id: fuel2_id, active: true}

      current_state = %AuctionState{
        auction_id: auction_id,
        status: :open,
        product_bids: %{
          "#{fuel1_id}" => %{
            lowest_bids: [fuel1_supplier1, fuel1_supplier2]
          },
          "#{fuel2_id}" => %{
            lowest_bids: [fuel2_supplier2, fuel2_supplier1]
          }
        }
      }

      %{solutions: %{best_single_supplier: solution}} = SolutionCalculator.process(current_state, auction)

      assert %{
        valid: true,
        bids: [^fuel1_supplier2, ^fuel2_supplier2]
      } = solution
    end

    test "uses latest time entered to break ties", %{
      auction: auction = %Auction{id: auction_id},
      fuel1: %Fuel{id: fuel1_id},
      fuel2: %Fuel{id: fuel2_id},
      supplier1: %{id: supplier1_id},
      supplier2: %{id: supplier2_id},
      supplier3: %{id: supplier3_id},
    } do
      fuel1_supplier2 = %AuctionBid{amount: 2.00, supplier_id: supplier2_id, auction_id: auction_id, fuel_id: fuel1_id, active: true, time_entered: DateTime.utc_now()}
      fuel2_supplier2 = %AuctionBid{amount: 2.50, supplier_id: supplier2_id, auction_id: auction_id, fuel_id: fuel2_id, active: true, time_entered: DateTime.utc_now()}
      fuel1_supplier1 = %AuctionBid{amount: 2.00, supplier_id: supplier1_id, auction_id: auction_id, fuel_id: fuel1_id, active: true, time_entered: DateTime.utc_now()}
      fuel2_supplier1 = %AuctionBid{amount: 2.50, supplier_id: supplier1_id, auction_id: auction_id, fuel_id: fuel2_id, active: true, time_entered: DateTime.utc_now()}
      fuel1_supplier3 = %AuctionBid{amount: 2.00, supplier_id: supplier3_id, auction_id: auction_id, fuel_id: fuel1_id, active: true, time_entered: DateTime.utc_now()}
      fuel2_supplier3 = %AuctionBid{amount: 3.00, supplier_id: supplier3_id, auction_id: auction_id, fuel_id: fuel2_id, active: true, time_entered: DateTime.utc_now()}

      current_state = %AuctionState{
        auction_id: auction_id,
        status: :open,
        product_bids: %{
          "#{fuel1_id}" => %{
            lowest_bids: [fuel1_supplier1, fuel1_supplier2, fuel1_supplier3]
          },
          "#{fuel2_id}" => %{
            lowest_bids: [fuel2_supplier1, fuel2_supplier2, fuel2_supplier3]
          }
        }
      }

      %{solutions: %{best_single_supplier: solution}} = SolutionCalculator.process(current_state, auction)

      assert %{
        valid: true,
        bids: [^fuel1_supplier2, ^fuel2_supplier2]
      } = solution
    end
  end
end
