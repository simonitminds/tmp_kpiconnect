defmodule Oceanconnect.Auctions.SolutionCalculatorTest do
  use Oceanconnect.DataCase
  alias Oceanconnect.Auctions.AuctionStore.AuctionState
  alias Oceanconnect.Auctions.SolutionCalculator
  alias Oceanconnect.Auctions.{Auction, AuctionBid, AuctionVesselFuel}

  setup do
    supplier_company = insert(:company)
    supplier2_company = insert(:company)
    supplier3_company = insert(:company)

    auction = insert(:auction, auction_vessel_fuels: [build(:vessel_fuel), build(:vessel_fuel)])
    [vessel_fuel1, vessel_fuel2] = auction.auction_vessel_fuels


    {:ok,
     %{
       auction: auction,
       vessel_fuel1: vessel_fuel1,
       vessel_fuel2: vessel_fuel2,
       supplier1: supplier_company,
       supplier2: supplier2_company,
       supplier3: supplier3_company
     }}
  end

  describe "process" do
    test "determines best overall bid combination from lowest bids", %{
      auction: auction = %Auction{id: auction_id},
      vessel_fuel1: %AuctionVesselFuel{id: vessel_fuel1_id},
      vessel_fuel2: %AuctionVesselFuel{id: vessel_fuel2_id},
      supplier1: %{id: supplier1_id},
      supplier2: %{id: supplier2_id},
      supplier3: %{id: supplier3_id}
    } do
      vessel_fuel1_supplier1 = %AuctionBid{
        amount: 2.00,
        supplier_id: supplier1_id,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel1_id,
        active: true
      }

      vessel_fuel1_supplier2 = %AuctionBid{
        amount: 2.50,
        supplier_id: supplier2_id,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel1_id,
        active: true
      }

      vessel_fuel2_supplier2 = %AuctionBid{
        amount: 3.00,
        supplier_id: supplier3_id,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel2_id,
        active: true
      }

      current_state = %AuctionState{
        auction_id: auction_id,
        status: :open,
        product_bids: %{
          "#{vessel_fuel1_id}" => %{
            lowest_bids: [vessel_fuel1_supplier1, vessel_fuel1_supplier2]
          },
          "#{vessel_fuel2_id}" => %{
            lowest_bids: [vessel_fuel2_supplier2]
          }
        }
      }

      %{solutions: %{best_overall: solution}} = SolutionCalculator.process(current_state, auction)

      assert %{
               valid: true,
               bids: [^vessel_fuel1_supplier1, ^vessel_fuel2_supplier2]
             } = solution
    end

    test "determines the best offer for each supplier", %{
      auction: auction = %Auction{id: auction_id},
      vessel_fuel1: %AuctionVesselFuel{id: vessel_fuel1_id},
      vessel_fuel2: %AuctionVesselFuel{id: vessel_fuel2_id},
      supplier1: %{id: supplier1_id},
      supplier2: %{id: supplier2_id},
      supplier3: %{id: _supplier3_id}
    } do
      vessel_fuel1_supplier1 = %AuctionBid{
        amount: 2.00,
        supplier_id: supplier1_id,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel1_id,
        active: true
      }

      vessel_fuel1_supplier2 = %AuctionBid{
        amount: 2.50,
        supplier_id: supplier2_id,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel1_id,
        active: true
      }

      fuel2_supplier1 = %AuctionBid{
        amount: 3.00,
        supplier_id: supplier1_id,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel2_id,
        active: true
      }

      current_state = %AuctionState{
        auction_id: auction_id,
        status: :open,
        product_bids: %{
          "#{vessel_fuel1_id}" => %{
            lowest_bids: [vessel_fuel1_supplier1, vessel_fuel1_supplier2]
          },
          "#{vessel_fuel2_id}" => %{
            lowest_bids: [fuel2_supplier1]
          }
        }
      }

      %{solutions: %{best_by_supplier: supplier_solutions}} =
        SolutionCalculator.process(current_state, auction)

      assert %{
               ^supplier1_id => %{
                 valid: true,
                 bids: [^vessel_fuel1_supplier1, ^fuel2_supplier1]
               },
               ^supplier2_id => %{
                 valid: false,
                 bids: [^vessel_fuel1_supplier2]
               }
             } = supplier_solutions
    end

    test "determines the best single supplier solution", %{
      auction: auction = %Auction{id: auction_id},
      vessel_fuel1: %AuctionVesselFuel{id: vessel_fuel1_id},
      vessel_fuel2: %AuctionVesselFuel{id: vessel_fuel2_id},
      supplier1: %{id: supplier1_id},
      supplier2: %{id: supplier2_id},
      supplier3: %{id: _supplier3_id}
    } do
      vessel_fuel1_supplier1 = %AuctionBid{
        amount: 2.00,
        supplier_id: supplier1_id,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel1_id,
        active: true
      }

      fuel2_supplier1 = %AuctionBid{
        amount: 3.00,
        supplier_id: supplier1_id,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel2_id,
        active: true
      }

      vessel_fuel1_supplier2 = %AuctionBid{
        amount: 2.50,
        supplier_id: supplier2_id,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel1_id,
        active: true
      }

      fuel2_supplier2 = %AuctionBid{
        amount: 2.00,
        supplier_id: supplier2_id,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel2_id,
        active: true
      }

      current_state = %AuctionState{
        auction_id: auction_id,
        status: :open,
        product_bids: %{
          "#{vessel_fuel1_id}" => %{
            lowest_bids: [vessel_fuel1_supplier1, vessel_fuel1_supplier2]
          },
          "#{vessel_fuel2_id}" => %{
            lowest_bids: [fuel2_supplier2, fuel2_supplier1]
          }
        }
      }

      %{solutions: %{best_single_supplier: solution}} =
        SolutionCalculator.process(current_state, auction)

      assert %{
               valid: true,
               bids: [^vessel_fuel1_supplier2, ^fuel2_supplier2]
             } = solution
    end

    test "uses latest original time entered to break ties", %{
      auction: auction = %Auction{id: auction_id},
      vessel_fuel1: %AuctionVesselFuel{id: vessel_fuel1_id},
      vessel_fuel2: %AuctionVesselFuel{id: vessel_fuel2_id},
      supplier1: %{id: supplier1_id},
      supplier2: %{id: supplier2_id},
      supplier3: %{id: supplier3_id}
    } do
      vessel_fuel1_supplier2 = %AuctionBid{
        amount: 2.00,
        supplier_id: supplier2_id,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel1_id,
        active: true,
        time_entered: DateTime.utc_now(),
        original_time_entered: DateTime.utc_now()
      }

      fuel2_supplier2 = %AuctionBid{
        amount: 2.50,
        supplier_id: supplier2_id,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel2_id,
        active: true,
        time_entered: DateTime.utc_now(),
        original_time_entered: DateTime.utc_now()
      }

      vessel_fuel1_supplier1 = %AuctionBid{
        amount: 2.00,
        supplier_id: supplier1_id,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel1_id,
        active: true,
        time_entered: DateTime.utc_now(),
        original_time_entered: DateTime.utc_now()
      }

      fuel2_supplier1 = %AuctionBid{
        amount: 2.50,
        supplier_id: supplier1_id,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel2_id,
        active: true,
        time_entered: DateTime.utc_now(),
        original_time_entered: DateTime.utc_now()
      }

      vessel_fuel1_supplier3 = %AuctionBid{
        amount: 2.00,
        supplier_id: supplier3_id,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel1_id,
        active: true,
        time_entered: DateTime.utc_now(),
        original_time_entered: DateTime.utc_now()
      }

      fuel2_supplier3 = %AuctionBid{
        amount: 3.00,
        supplier_id: supplier3_id,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel2_id,
        active: true,
        time_entered: DateTime.utc_now(),
        original_time_entered: DateTime.utc_now()
      }

      current_state = %AuctionState{
        auction_id: auction_id,
        status: :open,
        product_bids: %{
          "#{vessel_fuel1_id}" => %{
            lowest_bids: [vessel_fuel1_supplier1, vessel_fuel1_supplier2, vessel_fuel1_supplier3]
          },
          "#{vessel_fuel2_id}" => %{
            lowest_bids: [fuel2_supplier1, fuel2_supplier2, fuel2_supplier3]
          }
        }
      }

      %{solutions: %{best_single_supplier: solution}} =
        SolutionCalculator.process(current_state, auction)

      assert %{
               valid: true,
               bids: [^vessel_fuel1_supplier2, ^fuel2_supplier2]
             } = solution
    end

    test "respects allow_split when calculating best overall", %{
      auction: auction = %Auction{id: auction_id},
      vessel_fuel1: %AuctionVesselFuel{id: vessel_fuel1_id},
      vessel_fuel2: %AuctionVesselFuel{id: vessel_fuel2_id},
      supplier1: %{id: supplier1_id},
      supplier2: %{id: supplier2_id},
      supplier3: %{id: supplier3_id}
    } do
      # supplier2's vessel_fuel1 bid is the best for that product, but they do not
      # want to split. Because their vessel_fuel2 bid is so high, they're best
      # possible solution does not beat the best solution made from the
      # remaining bids.
      vessel_fuel1_supplier2 = %AuctionBid{
        amount: 1.00,
        supplier_id: supplier2_id,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel1_id,
        active: true,
        allow_split: false
      }

      vessel_fuel1_supplier1 = %AuctionBid{
        amount: 1.75,
        supplier_id: supplier1_id,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel1_id,
        active: true,
        allow_split: true
      }

      vessel_fuel1_supplier3 = %AuctionBid{
        amount: 2.00,
        supplier_id: supplier3_id,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel1_id,
        active: true,
        allow_split: true
      }

      fuel2_supplier1 = %AuctionBid{
        amount: 2.00,
        supplier_id: supplier1_id,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel2_id,
        active: true,
        allow_split: true
      }

      fuel2_supplier3 = %AuctionBid{
        amount: 2.50,
        supplier_id: supplier3_id,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel2_id,
        active: true,
        allow_split: true
      }

      fuel2_supplier2 = %AuctionBid{
        amount: 5.00,
        supplier_id: supplier2_id,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel2_id,
        active: true,
        allow_split: false
      }

      current_state = %AuctionState{
        auction_id: auction_id,
        status: :open,
        product_bids: %{
          "#{vessel_fuel1_id}" => %{
            lowest_bids: [vessel_fuel1_supplier2, vessel_fuel1_supplier1, vessel_fuel1_supplier3]
          },
          "#{vessel_fuel2_id}" => %{
            lowest_bids: [fuel2_supplier1, fuel2_supplier3, fuel2_supplier2]
          }
        }
      }

      %{solutions: %{best_overall: solution}} = SolutionCalculator.process(current_state, auction)

      assert %{
               valid: true,
               bids: [^vessel_fuel1_supplier1, ^fuel2_supplier1]
             } = solution
    end

    test "considers allow_split when calculating best overall with a single supplier beating remaining bids",
         %{
           auction: auction = %Auction{id: auction_id},
           vessel_fuel1: %AuctionVesselFuel{id: vessel_fuel1_id},
           vessel_fuel2: %AuctionVesselFuel{id: vessel_fuel2_id},
           supplier1: %{id: supplier1_id},
           supplier2: %{id: supplier2_id},
           supplier3: %{id: supplier3_id}
         } do
      # supplier2's vessel_fuel1 bid is the best for that product, but they do not
      # want to split. Because their vessel_fuel2 bid is still low enough to have a
      # lower normalized price than the remaining bids, they are considered the
      # best overall solution.
      vessel_fuel1_supplier2 = %AuctionBid{
        amount: 1.00,
        supplier_id: supplier2_id,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel1_id,
        active: true,
        allow_split: false
      }

      vessel_fuel1_supplier1 = %AuctionBid{
        amount: 1.75,
        supplier_id: supplier1_id,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel1_id,
        active: true,
        allow_split: true
      }

      vessel_fuel1_supplier3 = %AuctionBid{
        amount: 2.00,
        supplier_id: supplier3_id,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel1_id,
        active: true,
        allow_split: true
      }

      fuel2_supplier1 = %AuctionBid{
        amount: 2.00,
        supplier_id: supplier1_id,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel2_id,
        active: true,
        allow_split: true
      }

      fuel2_supplier2 = %AuctionBid{
        amount: 2.50,
        supplier_id: supplier2_id,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel2_id,
        active: true,
        allow_split: false
      }

      fuel2_supplier3 = %AuctionBid{
        amount: 3.00,
        supplier_id: supplier3_id,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel2_id,
        active: true,
        allow_split: true
      }

      current_state = %AuctionState{
        auction_id: auction_id,
        status: :open,
        product_bids: %{
          "#{vessel_fuel1_id}" => %{
            lowest_bids: [vessel_fuel1_supplier2, vessel_fuel1_supplier1, vessel_fuel1_supplier3]
          },
          "#{vessel_fuel2_id}" => %{
            lowest_bids: [fuel2_supplier1, fuel2_supplier2, fuel2_supplier3]
          }
        }
      }

      %{solutions: %{best_overall: solution}} = SolutionCalculator.process(current_state, auction)

      assert %{
               valid: true,
               bids: [^vessel_fuel1_supplier2, ^fuel2_supplier2]
             } = solution
    end
  end
end
