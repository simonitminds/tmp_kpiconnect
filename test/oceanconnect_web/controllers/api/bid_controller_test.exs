defmodule OceanconnectWeb.Api.BidControllerTest do
  use OceanconnectWeb.ConnCase
  use Bamboo.Test, shared: true
  alias Oceanconnect.Auctions
  alias Oceanconnect.Notifications.Emails

  setup do
    supplier_company = insert(:company, is_supplier: true)
    supplier2_company = insert(:company, is_supplier: true)
    supplier = insert(:user, company: supplier_company)
    supplier2 = insert(:user, company: supplier2_company)
    buyer = insert(:user)

    fuel1 = insert(:fuel)
    fuel2 = insert(:fuel)
    vessel1 = insert(:vessel)
    vessel2 = insert(:vessel)

    auction =
      insert(
        :auction,
        buyer: buyer.company,
        suppliers: [supplier_company, supplier2_company],
        auction_vessel_fuels: [
          build(:vessel_fuel, vessel: vessel1, fuel: fuel1),
          build(:vessel_fuel, vessel: vessel1, fuel: fuel2),
          build(:vessel_fuel, vessel: vessel2, fuel: fuel1),
          build(:vessel_fuel, vessel: vessel2, fuel: fuel2)
        ]
      )
      |> Auctions.fully_loaded()

    [vessel_fuel1, vessel_fuel2, vessel_fuel3, vessel_fuel4] = auction.auction_vessel_fuels

    {:ok, _pid} =
      start_supervised(
        {Oceanconnect.Auctions.AuctionSupervisor,
         {auction,
          %{
            exclude_children: [
              :auction_reminder_timer,
              :auction_event_handler,
              :auction_scheduler
            ]
          }}}
      )

    authed_conn = OceanconnectWeb.Plugs.Auth.api_login(build_conn(), supplier)

    bid_params = %{
      "bids" => %{
        vessel_fuel1.id => %{
          "amount" => "3.50",
          "min_amount" => "",
          "comment" => "",
          "allow_split" => true
        }
      }
    }

    {:ok,
     %{
       auction: auction,
       conn: authed_conn,
       buyer: buyer,
       bid_params: bid_params,
       fuel1: fuel1,
       supplier_company: supplier_company,
       supplier2_company: supplier2_company,
       supplier2: supplier2,
       vessel_fuel1: vessel_fuel1,
       vessel_fuel2: vessel_fuel2,
       vessel_fuel3: vessel_fuel3,
       vessel_fuel4: vessel_fuel4
     }}
  end

  test "creating a bid for a non-existing auction", %{
    conn: conn,
    auction: auction,
    bid_params: params
  } do
    fake_auction = %{id: auction.id + 9999, suppliers: auction.suppliers}
    conn = create_post(conn, fake_auction, params)
    assert json_response(conn, 422) == %{"success" => false, "message" => "Invalid bid"}
  end

  test "error when creating bid for auction in decision", %{
    conn: conn,
    auction: auction,
    bid_params: params
  } do
    updated_auction =
      auction
      |> Auctions.start_auction()
      |> Auctions.end_auction()

    conn = create_post(conn, updated_auction, params)

    assert json_response(conn, 409) == %{
             "success" => false,
             "message" => "Auction moved to decision before bid was received"
           }
  end

  test "error when creating bid for auction after decision", %{
    conn: conn,
    auction: auction,
    bid_params: params
  } do
    updated_auction =
      auction
      |> Auctions.start_auction()
      |> Auctions.end_auction()
      |> Auctions.expire_auction()

    conn = create_post(conn, updated_auction, params)
    assert json_response(conn, 422) == %{"success" => false, "message" => "Invalid bid"}
  end

  describe "open auction" do
    setup %{auction: auction} do
      Auctions.start_auction(auction)
      :ok
    end

    test "cannot bid when not logged in ", %{auction: auction, bid_params: params} do
      conn = create_post(build_conn(), auction, params)
      assert json_response(conn, 401)
    end

    test "cannot enter bids of non $0.25 increments ", %{
      conn: conn,
      auction: auction,
      bid_params: params,
      vessel_fuel1: vessel_fuel1,
      vessel_fuel2: vessel_fuel2
    } do
      updated_params =
        Map.put(params, "bids", %{
          vessel_fuel1.id => %{
            "amount" => "2.95",
            "min_amount" => "",
            "comment" => "",
            "allow_split" => true
          },
          vessel_fuel2.id => %{
            "amount" => "2.95",
            "min_amount" => "",
            "comment" => "",
            "allow_split" => true
          }
        })

      conn = create_post(conn, auction, updated_params)
      assert %{"success" => false, "message" => "Invalid bid"} = json_response(conn, 422)
    end

    test "creating a bid for an auction", %{auction: auction, conn: conn, bid_params: params} do
      conn = create_post(conn, auction, params)

      assert json_response(conn, 200) == %{
               "success" => true,
               "message" => "Bids successfully placed"
             }
    end

    test "creating multiple bids in a single request", %{
      auction: auction,
      conn: conn,
      vessel_fuel1: vessel_fuel1,
      vessel_fuel2: vessel_fuel2,
      vessel_fuel3: vessel_fuel3,
      vessel_fuel4: vessel_fuel4
    } do
      bid_params = %{
        "bids" => %{
          vessel_fuel1.id => %{
            "amount" => "3.50",
            "min_amount" => "",
            "comment" => "",
            "allow_split" => true
          },
          vessel_fuel2.id => %{
            "amount" => "3.50",
            "min_amount" => "",
            "comment" => "",
            "allow_split" => true
          },
          vessel_fuel3.id => %{
            "amount" => "2.50",
            "min_amount" => "",
            "comment" => "",
            "allow_split" => true
          },
          vessel_fuel4.id => %{
            "amount" => "2.50",
            "min_amount" => "",
            "comment" => "",
            "allow_split" => true
          }
        }
      }

      conn = create_post(conn, auction, bid_params)

      assert json_response(conn, 200) == %{
               "success" => true,
               "message" => "Bids successfully placed"
             }
    end

    test "creating a minimum bid with no bid for an auction", %{
      auction: auction,
      conn: conn,
      vessel_fuel1: vessel_fuel1,
      vessel_fuel2: vessel_fuel2
    } do
      conn =
        create_post(conn, auction, %{
          "bids" => %{
            vessel_fuel1.id => %{
              "amount" => "10.50",
              "min_amount" => "9.00",
              "allow_split" => true
            },
            vessel_fuel2.id => %{
              "amount" => "10.50",
              "min_amount" => "9.00",
              "allow_split" => true
            }
          }
        })

      assert json_response(conn, 200) == %{
               "success" => true,
               "message" => "Bids successfully placed"
             }
    end

    test "creating a bid for an auction as a non supplier", %{
      auction: auction,
      bid_params: params
    } do
      non_participant_company = insert(:company)
      non_participant = insert(:user, company: non_participant_company)
      conn = OceanconnectWeb.Plugs.Auth.api_login(build_conn(), non_participant)

      conn = post(conn, "#{auction_bid_api_path(conn, :create, auction.id)}", params)
      assert json_response(conn, 422) == %{"success" => false, "message" => "Invalid bid"}
    end

    test "creating a bid for an auction as a buyer", %{
      buyer: buyer,
      auction: auction,
      bid_params: params
    } do
      conn = OceanconnectWeb.Plugs.Auth.api_login(build_conn(), buyer)
      conn = post(conn, "#{auction_bid_api_path(conn, :create, auction.id)}", params)

      assert json_response(conn, 422) == %{"success" => false, "message" => "Invalid bid"}
    end

    test "creating a bid for an auction that doesn't allow traded bids", %{
      auction: auction,
      conn: conn,
      bid_params: params
    } do
      params = put_in(params["is_traded_bid"], true)
      conn = create_post(conn, auction, params)

      assert json_response(conn, 422) == %{
               "success" => false,
               "message" => "Auction not accepting traded bids"
             }
    end

    test "creating a non-splittable bid", %{
      auction: auction,
      conn: conn,
      vessel_fuel1: vessel_fuel1,
      vessel_fuel2: vessel_fuel2,
      vessel_fuel3: vessel_fuel3,
      vessel_fuel4: vessel_fuel4
    } do
      params = %{
        "bids" => %{
          vessel_fuel1.id => %{
            "amount" => "3.50",
            "min_amount" => "",
            "comment" => "",
            "allow_split" => false
          },
          vessel_fuel2.id => %{
            "amount" => "3.50",
            "min_amount" => "",
            "comment" => "",
            "allow_split" => false
          },
          vessel_fuel3.id => %{
            "amount" => "2.50",
            "min_amount" => "",
            "comment" => "",
            "allow_split" => false
          },
          vessel_fuel4.id => %{
            "amount" => "2.50",
            "min_amount" => "",
            "comment" => "",
            "allow_split" => false
          }
        }
      }

      conn = create_post(conn, auction, params)

      assert json_response(conn, 200) == %{
               "success" => true,
               "message" => "Bids successfully placed"
             }
    end

    test "creating a bid for a subset of vessels", %{
      auction: auction,
      conn: conn,
      vessel_fuel1: vessel_fuel1,
      vessel_fuel2: vessel_fuel2
    } do
      params = %{
        "bids" => %{
          vessel_fuel1.id => %{
            "amount" => "3.50",
            "min_amount" => "",
            "comment" => "",
            "allow_split" => false
          },
          vessel_fuel2.id => %{
            "amount" => "3.50",
            "min_amount" => "",
            "comment" => "",
            "allow_split" => false
          }
        }
      }

      conn = create_post(conn, auction, params)

      assert json_response(conn, 200) == %{
               "success" => true,
               "message" => "Bids successfully placed"
             }
    end

    test "creating a bid for an auction in decision", %{
      auction: auction,
      conn: conn,
      bid_params: params
    } do
      Auctions.end_auction(auction)
      conn = create_post(conn, auction, params)

      assert json_response(conn, 409) == %{
               "success" => false,
               "message" => "Auction moved to decision before bid was received"
             }
    end
  end

  describe "revoking bids" do
    setup %{
      auction: auction,
      conn: conn,
      vessel_fuel1: vessel_fuel1,
      vessel_fuel2: vessel_fuel2,
      vessel_fuel3: vessel_fuel3,
      vessel_fuel4: vessel_fuel4
    } do
      Auctions.start_auction(auction)

      bid_params = %{
        "bids" => %{
          vessel_fuel1.id => %{
            "amount" => "3.50",
            "min_amount" => "",
            "comment" => "",
            "allow_split" => true
          },
          vessel_fuel2.id => %{
            "amount" => "3.50",
            "min_amount" => "",
            "comment" => "",
            "allow_split" => true
          },
          vessel_fuel3.id => %{
            "amount" => "2.50",
            "min_amount" => "",
            "comment" => "",
            "allow_split" => true
          },
          vessel_fuel4.id => %{
            "amount" => "2.50",
            "min_amount" => "",
            "comment" => "",
            "allow_split" => true
          }
        }
      }

      create_post(conn, auction, bid_params)

      :ok
    end

    test "revoking a bid for a product from a supplier", %{
      auction: auction,
      conn: conn,
      supplier_company: supplier_company,
      vessel_fuel1: vessel_fuel1
    } do
      conn =
        revoke_post(conn, auction, %{
          "supplier" => "#{supplier_company.id}",
          "product" => vessel_fuel1.id
        })

      assert json_response(conn, 200) == %{
               "success" => true,
               "message" => "Bid successfully revoked"
             }
    end

    test "can NOT revoke a bid for another supplier", %{
      auction: auction,
      supplier_company: supplier_company,
      supplier2: supplier2,
      vessel_fuel1: vessel_fuel1
    } do
      conn = OceanconnectWeb.Plugs.Auth.api_login(build_conn(), supplier2)

      conn =
        revoke_post(conn, auction, %{
          "supplier" => "#{supplier_company.id}",
          "product" => vessel_fuel1.id
        })

      assert json_response(conn, 422) == %{"success" => false, "message" => "Invalid product"}
    end
  end

  test "revoking a bid for a term auction in decision", %{
    buyer: buyer,
    supplier_company: supplier_company,
    supplier2_company: supplier2_company,
    conn: conn,
    fuel1: fuel1
  } do
    term_auction =
      insert(
        :term_auction,
        buyer: buyer.company,
        suppliers: [supplier_company, supplier2_company]
      )
      |> Auctions.fully_loaded()

    Auctions.start_auction(term_auction)

    bid_params = %{
      "bids" => %{
        fuel1.id => %{
          "amount" => "3.50",
          "min_amount" => "",
          "comment" => "",
          "allow_split" => true
        }
      }
    }

    create_post(conn, term_auction, bid_params)

    Auctions.end_auction(term_auction)
    :timer.sleep(100)

    conn =
      revoke_post(conn, term_auction, %{
        "supplier" => "#{supplier_company.id}",
        "product" => fuel1.id
      })

    assert json_response(conn, 200) == %{
             "success" => true,
             "message" => "Bid successfully revoked"
           }
  end

  describe "select winning bid" do
    setup %{
      auction: auction,
      buyer: buyer,
      supplier_company: supplier_company,
      vessel_fuel1: vessel_fuel1,
      vessel_fuel2: vessel_fuel2
    } do
      {:ok, _pid} = Oceanconnect.Notifications.NotificationsSupervisor.start_link()
      Auctions.start_auction(auction)

      bids = [
        create_bid(1.25, nil, supplier_company.id, vessel_fuel1.id, auction),
        create_bid(1.25, nil, supplier_company.id, vessel_fuel2.id, auction)
      ]

      Enum.each(bids, fn bid -> Auctions.place_bid(bid, nil) end)

      Auctions.end_auction(auction)

      authed_conn = OceanconnectWeb.Plugs.Auth.api_login(build_conn(), buyer)
      {:ok, %{conn: authed_conn, bids: bids}}
    end

    test "buyer selects winning bid", %{auction: auction, conn: conn, bids: bids} do
      bid_ids = Enum.map(bids, & &1.id)

      new_conn =
        post(conn, auction_bid_api_path(conn, :select_solution, auction.id), %{
          comment: "test",
          port_agent: "",
          bid_ids: bid_ids
        })

      assert json_response(new_conn, 200)

      auction_state = Auctions.get_auction_state!(auction)

      assert Enum.all?(bids, fn bid -> bid in auction_state.winning_solution.bids end)
      assert auction_state.winning_solution.comment == "test"
      assert auction_state.status == :closed

      emails = Emails.AuctionClosed.generate(auction_state)

      :timer.sleep(1000)

      for email <- emails do
        assert_delivered_email(email)
      end
    end
  end

  defp create_post(conn, auction, params) do
    post(conn, "#{auction_bid_api_path(conn, :create, auction.id)}", params)
  end

  defp revoke_post(conn, auction, params) do
    post(conn, "#{auction_bid_api_path(conn, :revoke, auction.id)}", params)
  end
end
