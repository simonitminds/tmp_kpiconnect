defmodule OceanconnectWeb.AuctionsChannelTest do
  use OceanconnectWeb.ChannelCase
  alias Oceanconnect.Utilities
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{Auction, AuctionSupervisor}

  setup do
    buyer_company = insert(:company)
    insert(:user, company: buyer_company)
    supplier_company = insert(:company, is_supplier: true)
    supplier3_company = insert(:company, is_supplier: true)
    supplier_1 = insert(:user, company: supplier_company)
    supplier_2 = insert(:user, company: supplier_company)
    observer_company = insert(:company)
    observer = insert(:user, is_observer: true, company: observer_company)
    non_participant_company = insert(:company)
    non_participant = insert(:user, company: non_participant_company)
    fuel = insert(:fuel)
    fuel_id = "#{fuel.id}"

    auction =
      insert(
        :auction,
        buyer: buyer_company,
        duration: 1_000,
        decision_duration: 1_000,
        suppliers: [supplier_company, supplier3_company],
        observers: [observer],
        auction_vessel_fuels: [build(:vessel_fuel, fuel: fuel)]
      )
      |> Auctions.fully_loaded()

    [vessel_fuel] = auction.auction_vessel_fuels
    vessel_fuel_id = "#{vessel_fuel.id}"

    {:ok, _pid} =
      start_supervised(
        {AuctionSupervisor,
         {auction,
          %{
            exclude_children: [
              :auction_reminder_timer,
              :auction_scheduler,
              :auction_email_notification_handler
            ]
          }}}
      )

    expected_payload = %{
      time_remaining: auction.duration,
      bid_history: [],
      status: :open
    }

    {:ok,
     %{
       supplier_id: supplier_company.id,
       supplier_1: supplier_1,
       supplier_2: supplier_2,
       supplier3: supplier3_company,
       observer_id: observer_company.id,
       buyer_id: buyer_company.id,
       non_participant_id: non_participant_company.id,
       non_participant: non_participant,
       expected_payload: expected_payload,
       auction: auction,
       fuel_id: fuel_id,
       vessel_fuel_id: vessel_fuel_id
     }}
  end

  describe "auction timers expire" do
    test "user recieves a payload  update after the final duration timer expires", %{
      auction: auction,
      supplier_id: supplier_id
    } do
      auction_id = auction.id
      channel = "user_auctions:#{Integer.to_string(supplier_id)}"
      @endpoint.subscribe(channel)

      auction_attrs =
        auction
        |> Map.take([
          :scheduled_start,
          :fuel_id,
          :fuel_quantity,
          :port_id,
          :vessel_id,
          :auction_vessel_fuels,
          :suppliers,
          :buyer_id
        ])

      {:ok, %Auction{id: auction_id}} = Auctions.create_auction(auction_attrs)

      receive do
        _ -> assert true, "Received an update for create auction"
      after
        1000 ->
          assert false, "Never recieved the initial payload on create"
      end

      Auctions.expire_auction(auction)

      event = "auctions_update"

      receive do
        %Phoenix.Socket.Broadcast{
          event: ^event,
          payload: %{
            status: :expired,
            time_remaining: 0
          },
          topic: ^channel
        } ->
          assert true
      after
        5000 ->
          assert false, "Expected message after the timer expired received nothing."
      end
    end
  end

  describe "auction create/update" do
    test "supplier does not get notified for draft auction", %{
      auction: auction,
      supplier_id: supplier_id
    } do
      channel = "user_auctions:#{Integer.to_string(supplier_id)}"

      @endpoint.subscribe(channel)

      auction_attrs = auction |> Map.take([:port_id, :vessel_id, :suppliers])
      Auctions.create_auction(auction_attrs)

      receive do
        _ -> assert false, "Received an update for draft auction"
      after
        1000 ->
          assert true
      end
    end

    test "supplier gets notified for created schedulable auction", %{
      auction: auction,
      supplier_id: supplier_id
    } do
      channel = "user_auctions:#{Integer.to_string(supplier_id)}"
      event = "auctions_update"

      @endpoint.subscribe(channel)

      auction_attrs =
        auction
        |> Map.take([
          :scheduled_start,
          :fuel_id,
          :fuel_quantity,
          :port_id,
          :vessel_id,
          :auction_vessel_fuels,
          :suppliers,
          :buyer_id
        ])

      {:ok, %Auction{id: auction_id}} = Auctions.create_auction(auction_attrs)

      receive do
        %Phoenix.Socket.Broadcast{
          event: ^event,
          payload: %{
            auction: %{id: ^auction_id},
            status: :pending
          },
          topic: ^channel
        } ->
          assert true
      after
        5000 ->
          assert false, "Expected message received nothing."
      end
    end

    test "supplier gets notified for updated schedulable auction", %{
      auction: auction = %{id: auction_id},
      supplier_id: supplier_id
    } do
      channel = "user_auctions:#{Integer.to_string(supplier_id)}"
      event = "auctions_update"

      @endpoint.subscribe(channel)

      Auctions.update_auction(auction, %{port_agent: "TEST AGENT"}, auction.buyer)

      receive do
        %Phoenix.Socket.Broadcast{
          event: ^event,
          payload: %{
            auction: %{id: ^auction_id, port_agent: port_agent},
            status: :pending
          },
          topic: ^channel
        } ->
          assert port_agent == "TEST AGENT"
      after
        5000 ->
          assert false, "Expected message received nothing."
      end
    end
  end

  describe "auction start" do
    test "broadcasts are pushed to the buyer", %{
      buyer_id: buyer_id,
      auction: auction,
      expected_payload: expected_payload
    } do
      channel = "user_auctions:#{Integer.to_string(buyer_id)}"
      event = "auctions_update"

      @endpoint.subscribe(channel)
      Auctions.start_auction(auction)

      auction_id = auction.id

      receive do
        %Phoenix.Socket.Broadcast{
          event: ^event,
          payload: payload = %{auction: %{id: ^auction_id}, status: :open},
          topic: ^channel
        } ->
          assert Utilities.round_time_remaining(payload.time_remaining) ==
                   Utilities.round_time_remaining(expected_payload.time_remaining)
      after
        5000 ->
          assert false, "Expected message received nothing."
      end
    end

    test "broadcasts are pushed to the supplier", %{
      supplier_id: supplier_id,
      auction: auction,
      expected_payload: expected_payload
    } do
      channel = "user_auctions:#{Integer.to_string(supplier_id)}"
      event = "auctions_update"

      @endpoint.subscribe(channel)
      Auctions.start_auction(auction)

      auction_id = auction.id

      receive do
        %Phoenix.Socket.Broadcast{
          event: ^event,
          payload: payload = %{auction: %{id: ^auction_id}, status: :open},
          topic: ^channel
        } ->
          assert Utilities.round_time_remaining(payload.time_remaining) ==
                   Utilities.round_time_remaining(expected_payload.time_remaining)
      after
        5000 ->
          assert false, "Expected message received nothing."
      end
    end

    test "broadcasts are pushed to the observer", %{
      observer_id: observer_id,
      auction: auction,
      expected_payload: expected_payload
    } do
      channel = "user_auctions:#{Integer.to_string(observer_id)}"
      event = "auctions_update"

      @endpoint.subscribe(channel)
      Auctions.start_auction(auction)

      auction_id = auction.id

      receive do
        %Phoenix.Socket.Broadcast{
          event: ^event,
          payload: payload = %{auction: %{id: ^auction_id}, status: :open},
          topic: ^channel
        } ->
          assert Utilities.round_time_remaining(payload.time_remaining) ==
                   Utilities.round_time_remaining(expected_payload.time_remaining)
      after
        5000 ->
          assert false, "Expected message received nothing."
      end
    end

    test "broadcasts are not pushed to a non_participant", %{
      non_participant_id: non_participant_id,
      auction: auction,
      expected_payload: expected_payload
    } do
      channel = "user_auctions:#{Integer.to_string(non_participant_id)}"
      event = "auctions_update"

      @endpoint.subscribe(channel)
      Auctions.start_auction(auction)

      refute_broadcast(^event, ^expected_payload)
    end

    test "two users from the same company can join their companies channel", %{
      supplier_id: supplier_company_id,
      supplier_2: supplier_2
    } do
      channel = "user_auctions:#{supplier_company_id}"
      user_with_company = Oceanconnect.Accounts.load_company_on_user(supplier_2)

      {:ok, supplier_2_participant_token, _claims} =
        Oceanconnect.Guardian.encode_and_sign(user_with_company)

      {:ok, supplier_2_socket} =
        connect(OceanconnectWeb.UserSocket, %{"token" => supplier_2_participant_token})

      assert {:ok, %{}, _socket} =
               subscribe_and_join(supplier_2_socket, OceanconnectWeb.AuctionsChannel, channel, %{
                 "token" => supplier_2_participant_token
               })
    end

    test "joining another companies auction channel is unauthorized", %{
      supplier_id: supplier_id,
      non_participant: non_participant
    } do
      channel = "user_auctions:#{Integer.to_string(supplier_id)}"
      user_with_company = Oceanconnect.Accounts.load_company_on_user(non_participant)

      {:ok, non_participant_token, _claims} =
        Oceanconnect.Guardian.encode_and_sign(user_with_company)

      {:ok, non_participant_socket} =
        connect(OceanconnectWeb.UserSocket, %{token: non_participant_token})

      assert {:error, %{reason: "unauthorized"}} =
               subscribe_and_join(
                 non_participant_socket,
                 OceanconnectWeb.AuctionsChannel,
                 channel
               )
    end
  end

  describe "auction goes into decision" do
    setup(%{auction: auction, expected_payload: expected_payload}) do
      payload =
        expected_payload
        |> Map.put(:time_remaining, auction.decision_duration)
        |> Map.put(:status, :decision)

      Auctions.start_auction(auction)
      {:ok, %{expected_payload: payload}}
    end

    test "buyers get notified with timer timeout", %{
      auction: auction,
      buyer_id: buyer_id,
      expected_payload: expected_payload
    } do
      channel = "user_auctions:#{Integer.to_string(buyer_id)}"
      event = "auctions_update"

      @endpoint.subscribe(channel)

      auction_id = auction.id

      receive do
        %Phoenix.Socket.Broadcast{
          event: ^event,
          payload: payload = %{auction: %{id: ^auction_id}, status: :decision},
          topic: ^channel
        } ->
          assert Utilities.round_time_remaining(payload.time_remaining) ==
                   Utilities.round_time_remaining(expected_payload.time_remaining)
      after
        5000 ->
          assert false, "Expected message received nothing."
      end
    end

    test "suppliers get notified", %{
      auction: auction,
      supplier_id: supplier_id,
      expected_payload: expected_payload
    } do
      channel = "user_auctions:#{Integer.to_string(supplier_id)}"
      event = "auctions_update"

      @endpoint.subscribe(channel)
      Auctions.end_auction(auction)

      auction_id = auction.id

      receive do
        %Phoenix.Socket.Broadcast{
          event: ^event,
          payload: payload = %{auction: %{id: ^auction_id}, status: :decision},
          topic: ^channel
        } ->
          assert Utilities.round_time_remaining(payload.time_remaining) ==
                   Utilities.round_time_remaining(expected_payload.time_remaining)
      after
        5000 ->
          assert false, "Expected message received nothing."
      end
    end

    test "observers get notified", %{
      auction: auction,
      observer_id: observer_id,
      expected_payload: expected_payload
    } do
      channel = "user_auctions:#{Integer.to_string(observer_id)}"
      event = "auctions_update"

      @endpoint.subscribe(channel)
      Auctions.end_auction(auction)

      auction_id = auction.id

      receive do
        %Phoenix.Socket.Broadcast{
          event: ^event,
          payload: payload = %{auction: %{id: ^auction_id}, status: :decision},
          topic: ^channel
        } ->
          assert Utilities.round_time_remaining(payload.time_remaining) ==
                   Utilities.round_time_remaining(expected_payload.time_remaining)
      after
        5000 ->
          assert false, "Expected message received nothing."
      end
    end

    test "a non participant is not notified", %{
      auction: auction,
      non_participant_id: non_participant_id,
      expected_payload: expected_payload
    } do
      channel = "user_auctions:#{Integer.to_string(non_participant_id)}"
      event = "auctions_update"

      @endpoint.subscribe(channel)
      Auctions.end_auction(auction)

      refute_broadcast(^event, ^expected_payload)
    end
  end

  describe "auction expires (decision period runs out with no selection)" do
    setup(%{auction: auction, expected_payload: expected_payload}) do
      payload =
        expected_payload
        |> Map.put(:time_remaining, 0)
        |> Map.put(:status, :expired)

      auction
      |> Auctions.start_auction()
      |> Auctions.end_auction()

      {:ok, %{expected_payload: payload}}
    end

    test "buyers get notified with timer timeout", %{
      auction: auction,
      buyer_id: buyer_id,
      expected_payload: expected_payload
    } do
      channel = "user_auctions:#{Integer.to_string(buyer_id)}"
      event = "auctions_update"

      @endpoint.subscribe(channel)

      auction_id = auction.id

      receive do
        %Phoenix.Socket.Broadcast{
          event: ^event,
          payload: payload = %{auction: %{id: ^auction_id}, status: :expired},
          topic: ^channel
        } ->
          assert Utilities.round_time_remaining(payload.time_remaining) ==
                   Utilities.round_time_remaining(expected_payload.time_remaining)
      after
        5000 ->
          assert false, "Expected message received nothing."
      end
    end

    test "suppliers get notified", %{
      auction: auction,
      supplier_id: supplier_id,
      expected_payload: expected_payload
    } do
      channel = "user_auctions:#{Integer.to_string(supplier_id)}"
      event = "auctions_update"

      @endpoint.subscribe(channel)
      Auctions.expire_auction(auction)

      auction_id = auction.id

      receive do
        %Phoenix.Socket.Broadcast{
          event: ^event,
          payload: payload = %{auction: %{id: ^auction_id}, status: :expired},
          topic: ^channel
        } ->
          assert Utilities.round_time_remaining(payload.time_remaining) ==
                   Utilities.round_time_remaining(expected_payload.time_remaining)
      after
        5000 ->
          assert false, "Expected message received nothing."
      end
    end

    test "observers get notified", %{
      auction: auction,
      observer_id: observer_id,
      expected_payload: expected_payload
    } do
      channel = "user_auctions:#{Integer.to_string(observer_id)}"
      event = "auctions_update"

      @endpoint.subscribe(channel)
      Auctions.expire_auction(auction)

      auction_id = auction.id

      receive do
        %Phoenix.Socket.Broadcast{
          event: ^event,
          payload: payload = %{auction: %{id: ^auction_id}, status: :expired},
          topic: ^channel
        } ->
          assert Utilities.round_time_remaining(payload.time_remaining) ==
                   Utilities.round_time_remaining(expected_payload.time_remaining)
      after
        5000 ->
          assert false, "Expected message received nothing."
      end
    end

    test "a non participant is not notified", %{
      auction: auction,
      non_participant_id: non_participant_id,
      expected_payload: expected_payload
    } do
      channel = "user_auctions:#{Integer.to_string(non_participant_id)}"
      event = "auctions_update"

      @endpoint.subscribe(channel)
      Auctions.expire_auction(auction)

      refute_broadcast(^event, ^expected_payload)
    end
  end

  describe "placing bids" do
    setup %{auction: auction} do
      Auctions.start_auction(auction)
      :ok
    end

    test "buyers get notified", %{
      auction: auction = %{id: auction_id},
      buyer_id: buyer_id,
      supplier_id: supplier_id,
      vessel_fuel_id: vessel_fuel_id
    } do
      channel = "user_auctions:#{Integer.to_string(buyer_id)}"
      event = "auctions_update"

      @endpoint.subscribe(channel)

      create_bid(1.25, nil, supplier_id, vessel_fuel_id, auction, false)
      |> Auctions.place_bid()

      buyer_auction_payload =
        auction
        |> Auctions.AuctionPayload.get_auction_payload!(buyer_id)

      buyer_payload = buyer_auction_payload.product_bids[vessel_fuel_id]

      receive do
        _ -> nil
      after
        5000 ->
          assert false, "Expected message received nothing."
      end

      receive do
        %Phoenix.Socket.Broadcast{
          event: ^event,
          payload: %{
            auction: %{id: ^auction_id},
            status: :open,
            product_bids: %{
              ^vessel_fuel_id => %{
                lowest_bids: lowest_bids,
                bid_history: bid_history
              }
            }
          },
          topic: ^channel
        } ->
          assert buyer_payload.bid_history == bid_history
          assert buyer_payload.lowest_bids == lowest_bids
      after
        5000 ->
          assert false, "Expected message received nothing."
      end

      Auctions.end_auction(auction)

      decision_buyer_auction_payload =
        auction
        |> Auctions.AuctionPayload.get_auction_payload!(buyer_id)

      decision_buyer_payload = decision_buyer_auction_payload.product_bids[vessel_fuel_id]

      receive do
        %Phoenix.Socket.Broadcast{
          event: ^event,
          payload: %{
            auction: %{id: ^auction_id},
            status: :decision,
            product_bids: %{
              ^vessel_fuel_id => %{
                lowest_bids: lowest_bids,
                bid_history: bid_history
              }
            }
          },
          topic: ^channel
        } ->
          assert decision_buyer_payload.bid_history == bid_history
          assert decision_buyer_payload.lowest_bids == lowest_bids
      after
        5000 ->
          assert false, "Expected message received nothing."
      end
    end

    test "suppliers get notified", %{
      auction: auction = %{id: auction_id},
      supplier_id: supplier_id,
      supplier3: supplier3,
      vessel_fuel_id: vessel_fuel_id
    } do
      channel = "user_auctions:#{Integer.to_string(supplier_id)}"
      event = "auctions_update"

      @endpoint.subscribe(channel)

      create_bid(1.25, nil, supplier_id, vessel_fuel_id, auction, false)
      |> Auctions.place_bid()

      supplier_auction_payload =
        auction
        |> Auctions.AuctionPayload.get_auction_payload!(supplier_id)

      supplier_payload = supplier_auction_payload.product_bids[vessel_fuel_id]

      # NOTE: There seems to be an extra event that gets sent when bids are
      # placed that does not contain the bids. Unsure of where this event is
      # coming from.
      receive do
        %Phoenix.Socket.Broadcast{topic: ^channel} -> nil
      after
        5000 -> assert false, "Expected message received nothing."
      end

      receive do
        %Phoenix.Socket.Broadcast{
          event: ^event,
          payload: %{
            auction: auction = %{id: ^auction_id},
            status: :open,
            product_bids: %{
              ^vessel_fuel_id => %{
                lowest_bids: lowest_bids,
                bid_history: bid_history
              }
            },
            time_remaining: time_remaining
          },
          topic: ^channel
        } ->
          assert supplier_payload.bid_history == bid_history
          assert supplier_payload.lowest_bids == lowest_bids
          refute auction |> Map.has_key?(:suppliers)
          # Auction extended
          assert time_remaining > 3 * 60_000 - 1_000
      after
        5000 ->
          assert false, "Expected message received nothing."
      end

      create_bid(1.25, nil, supplier3.id, vessel_fuel_id, auction, false)
      |> Auctions.place_bid()

      receive do
        %Phoenix.Socket.Broadcast{topic: ^channel} -> nil
      after
        5000 ->
          assert false, "Expected message received nothing."
      end

      Auctions.end_auction(auction)

      decision_supplier_auction_payload =
        auction
        |> Auctions.AuctionPayload.get_auction_payload!(supplier_id)

      decision_supplier_payload = decision_supplier_auction_payload.product_bids[vessel_fuel_id]

      receive do
        %Phoenix.Socket.Broadcast{
          event: ^event,
          payload: %{
            auction: auction = %{id: ^auction_id},
            status: :decision,
            product_bids: %{
              ^vessel_fuel_id => %{
                lowest_bids: lowest_bids,
                bid_history: bid_history
              }
            },
            time_remaining: time_remaining
          },
          topic: ^channel
        } ->
          assert decision_supplier_payload.bid_history == bid_history
          assert decision_supplier_payload.lowest_bids == lowest_bids
          refute auction |> Map.has_key?(:suppliers)
          assert time_remaining > auction.decision_duration - 1_000
      after
        5000 ->
          assert false, "Expected message received nothing."
      end
    end

    test "observers get notified", %{
      auction: auction = %{id: auction_id},
      observer_id: observer_id,
      supplier_id: supplier_id,
      vessel_fuel_id: vessel_fuel_id
    } do
      channel = "user_auctions:#{Integer.to_string(observer_id)}"
      event = "auctions_update"

      @endpoint.subscribe(channel)

      create_bid(1.25, nil, supplier_id, vessel_fuel_id, auction, false)
      |> Auctions.place_bid()

      observer_auction_payload =
        Auctions.AuctionPayload.get_auction_payload!(auction, observer_id)

      observer_payload = observer_auction_payload.product_bids[vessel_fuel_id]

      receive do
        %Phoenix.Socket.Broadcast{topic: ^channel} -> nil
      after
        5000 -> assert false, "Expected message received nothing."
      end

      receive do
        %Phoenix.Socket.Broadcast{
          event: ^event,
          payload: %{
            auction: auction = %{id: ^auction_id},
            status: :open,
            product_bids: %{
              ^vessel_fuel_id => %{
                lowest_bids: lowest_bids,
                bid_history: bid_history
              }
            }
          },
          topic: ^channel
        } ->
          assert observer_payload.bid_history == bid_history
          assert observer_payload.lowest_bids == lowest_bids
      after
        5000 ->
          assert false, "Expected message received nothing."
      end

      Auctions.end_auction(auction)

      decision_observer_auction_payload =
        Auctions.AuctionPayload.get_auction_payload!(auction, observer_id)

      decision_observer_payload = decision_observer_auction_payload.product_bids[vessel_fuel_id]

      receive do
        %Phoenix.Socket.Broadcast{
          event: ^event,
          payload: %{
            auction: auction = %{id: ^auction_id},
            status: :decision,
            product_bids: %{
              ^vessel_fuel_id => %{
                lowest_bids: lowest_bids,
                bid_history: bid_history
              }
            }
          },
          topic: ^channel
        } ->
          assert decision_observer_payload.bid_history == bid_history
          assert decision_observer_payload.lowest_bids == lowest_bids
      after
        5000 ->
          assert false, "Expected message received nothing."
      end
    end

    test "a non participant is not notified", %{non_participant_id: non_participant_id} do
      channel = "user_auctions:#{Integer.to_string(non_participant_id)}"
      event = "auctions_update"

      @endpoint.subscribe(channel)

      refute_broadcast(^event, %{})
    end
  end
end
