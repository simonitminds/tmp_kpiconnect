defmodule Oceanconnect.Auctions.SolutionCalculatorTest do
  use Oceanconnect.DataCase
  alias Oceanconnect.Auctions.SolutionCalculator
  alias Oceanconnect.Auctions.{Auction, AuctionBid, AuctionVesselFuel, SpotAuctionState}

  def quick_bid(amount, vfid, supplier_id, auction_id, opts \\ []) do
    now = DateTime.utc_now()
    %AuctionBid{
      amount: amount,
      supplier_id: supplier_id,
      auction_id: auction_id,
      vessel_fuel_id: "#{vfid}",
      active: true,
      allow_split: Keyword.get(opts, :allow_split, true),
      time_entered: Keyword.get(opts, :time_entered, now),
      original_time_entered: Keyword.get(opts, :time_entered, now)
    }
  end

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
      vessel_fuel1: %AuctionVesselFuel{id: vf1_id},
      vessel_fuel2: %AuctionVesselFuel{id: vf2_id},
      supplier1: %{id: supplier1_id},
      supplier2: %{id: supplier2_id},
      supplier3: %{id: supplier3_id}
    } do
      vf1_supplier1 = quick_bid(2.00, vf1_id, supplier1_id, auction_id)
      vf1_supplier2 = quick_bid(2.50, vf1_id, supplier2_id, auction_id)
      vf2_supplier2 = quick_bid(3.00, vf2_id, supplier3_id, auction_id)

      current_state = %SpotAuctionState{
        auction_id: auction_id,
        status: :open,
        product_bids: %{
          "#{vf1_id}" => %{
            lowest_bids: [vf1_supplier1, vf1_supplier2]
          },
          "#{vf2_id}" => %{
            lowest_bids: [vf2_supplier2]
          }
        }
      }

      %{solutions: %{best_overall: solution}} = SolutionCalculator.process(current_state, auction)

      assert %{
               valid: true,
               bids: [^vf1_supplier1, ^vf2_supplier2]
             } = solution
    end

    test "determines the best offer for each supplier", %{
      auction: auction = %Auction{id: auction_id},
      vessel_fuel1: %AuctionVesselFuel{id: vf1_id},
      vessel_fuel2: %AuctionVesselFuel{id: vf2_id},
      supplier1: %{id: supplier1_id},
      supplier2: %{id: supplier2_id},
      supplier3: %{id: _supplier3_id}
    } do
      vf1_supplier1 = quick_bid(2.00, vf1_id, supplier1_id, auction_id)
      vf1_supplier2 = quick_bid(2.50, vf1_id, supplier2_id, auction_id)
      vf2_supplier1 = quick_bid(3.00, vf2_id, supplier1_id, auction_id)

      current_state = %SpotAuctionState{
        auction_id: auction_id,
        status: :open,
        product_bids: %{
          "#{vf1_id}" => %{
            lowest_bids: [vf1_supplier1, vf1_supplier2]
          },
          "#{vf2_id}" => %{
            lowest_bids: [vf2_supplier1]
          }
        }
      }

      %{solutions: %{best_by_supplier: supplier_solutions}} =
        SolutionCalculator.process(current_state, auction)

      assert %{
               ^supplier1_id => %{
                 valid: true,
                 bids: [^vf1_supplier1, ^vf2_supplier1]
               },
               ^supplier2_id => %{
                 valid: false,
                 bids: [^vf1_supplier2]
               }
             } = supplier_solutions
    end

    test "determines the best single supplier solution", %{
      auction: auction = %Auction{id: auction_id},
      vessel_fuel1: %AuctionVesselFuel{id: vf1_id},
      vessel_fuel2: %AuctionVesselFuel{id: vf2_id},
      supplier1: %{id: supplier1_id},
      supplier2: %{id: supplier2_id},
      supplier3: %{id: _supplier3_id}
    } do
      vf1_supplier1 = quick_bid(2.00, vf1_id, supplier1_id, auction_id)
      vf2_supplier1 = quick_bid(3.00, vf2_id, supplier1_id, auction_id)
      vf1_supplier2 = quick_bid(2.50, vf1_id, supplier2_id, auction_id)
      vf2_supplier2 = quick_bid(2.00, vf2_id, supplier2_id, auction_id)

      current_state = %SpotAuctionState{
        auction_id: auction_id,
        status: :open,
        product_bids: %{
          "#{vf1_id}" => %{
            lowest_bids: [vf1_supplier1, vf1_supplier2]
          },
          "#{vf2_id}" => %{
            lowest_bids: [vf2_supplier2, vf2_supplier1]
          }
        }
      }

      %{solutions: %{best_single_supplier: solution}} =
        SolutionCalculator.process(current_state, auction)

      assert %{
               valid: true,
               bids: [^vf1_supplier2, ^vf2_supplier2]
             } = solution
    end

    test "uses latest original time entered to break ties", %{
      auction: auction = %Auction{id: auction_id},
      vessel_fuel1: %AuctionVesselFuel{id: vf1_id},
      vessel_fuel2: %AuctionVesselFuel{id: vf2_id},
      supplier1: %{id: supplier1_id},
      supplier2: %{id: supplier2_id},
      supplier3: %{id: supplier3_id}
    } do
      vf1_supplier2 = quick_bid(2.00, vf1_id, supplier2_id, auction_id, time_entered: DateTime.utc_now())
      vf2_supplier2 = quick_bid(2.50, vf2_id, supplier2_id, auction_id, time_entered: DateTime.utc_now())
      vf1_supplier1 = quick_bid(2.00, vf1_id, supplier1_id, auction_id, time_entered: DateTime.utc_now())
      vf2_supplier1 = quick_bid(2.50, vf2_id, supplier1_id, auction_id, time_entered: DateTime.utc_now())
      vf1_supplier3 = quick_bid(2.00, vf1_id, supplier3_id, auction_id, time_entered: DateTime.utc_now())
      vf2_supplier3 = quick_bid(3.00, vf2_id, supplier3_id, auction_id, time_entered: DateTime.utc_now())

      current_state = %SpotAuctionState{
        auction_id: auction_id,
        status: :open,
        product_bids: %{
          "#{vf1_id}" => %{
            lowest_bids: [vf1_supplier1, vf1_supplier2, vf1_supplier3]
          },
          "#{vf2_id}" => %{
            lowest_bids: [vf2_supplier1, vf2_supplier2, vf2_supplier3]
          }
        }
      }

      %{solutions: %{best_single_supplier: solution}} =
        SolutionCalculator.process(current_state, auction)

      assert %{
               valid: true,
               bids: [^vf1_supplier2, ^vf2_supplier2]
             } = solution
    end

    test "respects allow_split when calculating best overall", %{
      auction: auction = %Auction{id: auction_id},
      vessel_fuel1: %AuctionVesselFuel{id: vf1_id},
      vessel_fuel2: %AuctionVesselFuel{id: vf2_id},
      supplier1: %{id: supplier1_id},
      supplier2: %{id: supplier2_id},
      supplier3: %{id: supplier3_id}
    } do
      # supplier2's vessel_fuel1 bid is the best for that product, but they do not
      # want to split. Because their vessel_fuel2 bid is so high, they're best
      # possible solution does not beat the best solution made from the
      # remaining bids.
      vf1_supplier2 = quick_bid(1.00, vf1_id, supplier2_id, auction_id, allow_split: false)
      vf1_supplier1 = quick_bid(1.75, vf1_id, supplier1_id, auction_id, allow_split: true)
      vf1_supplier3 = quick_bid(2.00, vf1_id, supplier3_id, auction_id, allow_split: true)
      vf2_supplier1 = quick_bid(2.00, vf2_id, supplier1_id, auction_id, allow_split: true)
      vf2_supplier3 = quick_bid(2.50, vf2_id, supplier3_id, auction_id, allow_split: true)
      vf2_supplier2 = quick_bid(5.00, vf2_id, supplier2_id, auction_id, allow_split: false)

      current_state = %SpotAuctionState{
        auction_id: auction_id,
        status: :open,
        product_bids: %{
          "#{vf1_id}" => %{
            lowest_bids: [vf1_supplier2, vf1_supplier1, vf1_supplier3]
          },
          "#{vf2_id}" => %{
            lowest_bids: [vf2_supplier1, vf2_supplier3, vf2_supplier2]
          }
        }
      }

      %{solutions: %{best_overall: solution}} = SolutionCalculator.process(current_state, auction)

      assert %{
               valid: true,
               bids: [^vf1_supplier1, ^vf2_supplier1]
             } = solution
    end

    test "considers allow_split when calculating best overall with a single supplier beating remaining bids", %{
      auction: auction = %Auction{id: auction_id},
      vessel_fuel1: %AuctionVesselFuel{id: vf1_id},
      vessel_fuel2: %AuctionVesselFuel{id: vf2_id},
      supplier1: %{id: supplier1_id},
      supplier2: %{id: supplier2_id},
      supplier3: %{id: supplier3_id}
    } do
      # supplier2's vessel_fuel1 bid is the best for that product, but they do not
      # want to split. Because their vessel_fuel2 bid is still low enough to have a
      # lower normalized price than the remaining bids, they are considered the
      # best overall solution.
      vf1_supplier2 = quick_bid(1.00, vf1_id, supplier2_id, auction_id, allow_split: false)
      vf1_supplier1 = quick_bid(1.75, vf1_id, supplier1_id, auction_id, allow_split: true)
      vf1_supplier3 = quick_bid(2.00, vf1_id, supplier3_id, auction_id, allow_split: true)
      vf2_supplier1 = quick_bid(2.00, vf2_id, supplier1_id, auction_id, allow_split: true)
      vf2_supplier2 = quick_bid(2.50, vf2_id, supplier2_id, auction_id, allow_split: false)
      vf2_supplier3 = quick_bid(3.00, vf2_id, supplier3_id, auction_id, allow_split: true)

      current_state = %SpotAuctionState{
        auction_id: auction_id,
        status: :open,
        product_bids: %{
          "#{vf1_id}" => %{
            lowest_bids: [vf1_supplier2, vf1_supplier1, vf1_supplier3]
          },
          "#{vf2_id}" => %{
            lowest_bids: [vf2_supplier1, vf2_supplier2, vf2_supplier3]
          }
        }
      }

      %{solutions: %{best_overall: solution}} = SolutionCalculator.process(current_state, auction)

      assert %{
               valid: true,
               bids: [^vf1_supplier2, ^vf2_supplier2]
             } = solution
    end

    test "respects allow_split with other bids from same supplier", %{} do
      suppliers = insert_list(5, :company)
      [s1, s2, s3, s4, s5] = suppliers
      vessel_fuels = insert_list(6, :vessel_fuel)
      [vf1, vf2, vf3, vf4, vf5, vf6] = vessel_fuels
      auction = insert(:auction, suppliers: suppliers, auction_vessel_fuels: vessel_fuels)

      # - Supplier A
      #   :a  5
      #   :b  5
      #   :c 25 no split
      #   :e 12
      # - Supplier B
      #   :a  4 no split
      #   :b  7
      #   :c  7
      #   :d  5 no split
      # - Supplier C
      #   :a 6 no split
      #   :b 6
      #   :e 6 no split
      # - Supplier D
      #   :c 10
      #   :d 15 no split
      # - Supplier E
      #   :a  6 no split
      #   :f 12 no split
      vf1_s1 = quick_bid( 5.00, vf1.id, s1.id, auction.id, allow_split: true)
      vf2_s1 = quick_bid( 5.00, vf2.id, s1.id, auction.id, allow_split: true)
      vf3_s1 = quick_bid(25.00, vf3.id, s1.id, auction.id, allow_split: false)
      vf5_s1 = quick_bid(12.00, vf5.id, s1.id, auction.id, allow_split: true)

      vf1_s2 = quick_bid( 4.00, vf1.id, s2.id, auction.id, allow_split: false)
      vf2_s2 = quick_bid( 7.00, vf2.id, s2.id, auction.id, allow_split: true)
      vf3_s2 = quick_bid( 7.00, vf3.id, s2.id, auction.id, allow_split: true)
      vf4_s2 = quick_bid( 5.00, vf4.id, s2.id, auction.id, allow_split: false)

      vf1_s3 = quick_bid( 6.00, vf1.id, s3.id, auction.id, allow_split: false)
      vf2_s3 = quick_bid( 6.00, vf2.id, s3.id, auction.id, allow_split: true)
      vf5_s3 = quick_bid( 6.00, vf5.id, s3.id, auction.id, allow_split: false)

      vf3_s4 = quick_bid(10.00, vf3.id, s4.id, auction.id, allow_split: true)
      vf4_s4 = quick_bid(15.00, vf4.id, s4.id, auction.id, allow_split: false)

      vf1_s5 = quick_bid( 6.00, vf1.id, s5.id, auction.id, allow_split: false)
      vf6_s5 = quick_bid(12.00, vf6.id, s5.id, auction.id, allow_split: false)


      current_state = %SpotAuctionState{
        auction_id: auction.id,
        status: :open,
        product_bids: %{
          "#{vf1.id}" => %{lowest_bids: [vf1_s2, vf1_s1, vf1_s3, vf1_s5]},
          "#{vf2.id}" => %{lowest_bids: [vf2_s1, vf2_s3, vf2_s2]},
          "#{vf3.id}" => %{lowest_bids: [vf3_s2, vf3_s4, vf3_s1]},
          "#{vf4.id}" => %{lowest_bids: [vf4_s2, vf4_s4]},
          "#{vf5.id}" => %{lowest_bids: [vf5_s3, vf5_s1]},
          "#{vf6.id}" => %{lowest_bids: [vf6_s5]}
        }
      }

      %{solutions: %{best_overall: solution}} = SolutionCalculator.process(current_state, auction)

      %{valid: true, bids: bids} = solution
      assert [^vf1_s5, ^vf2_s1, ^vf3_s4, ^vf4_s4, ^vf5_s1, ^vf6_s5] = Enum.sort_by(bids, &(&1.vessel_fuel_id))
    end
  end
end
