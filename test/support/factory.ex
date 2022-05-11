defmodule Oceanconnect.Factory do
  use ExMachina.Ecto, repo: Oceanconnect.Repo

  alias Oceanconnect.Auctions.{
    Auction,
    TermAuction,
    AuctionEventStore,
    Solution,
    Command,
    Aggregate
  }

  def set_password(user) do
    hashed_password = Bcrypt.hash_pwd_salt(user.password)
    %{user | password_hash: hashed_password}
  end

  def company_factory() do
    %Oceanconnect.Accounts.Company{
      name: sequence(:name, &"Company-#{&1}"),
      contact_name: sequence(:contact_name, &"test-#{&1}")
    }
  end

  def user_factory() do
    %Oceanconnect.Accounts.User{
      email: sequence(:email, &"USER-#{&1}@EXAMPLE.COM"),
      first_name: sequence(:first_name, &"test-#{&1}"),
      last_name: sequence(:first_name, &"user-#{&1}"),
      office_phone: "office phone",
      mobile_phone: "mobile phone",
      password: "password",
      company: build(:company)
    }
    |> set_password
  end

  def auction_supplier_coq_factory() do
    %Oceanconnect.Auctions.AuctionSupplierCOQ{
      auction: build(:auction),
      fuel: build(:fuel),
      supplier: build(:company),
      file_extension: "pdf"
    }
  end

  def create_auction_supplier_coq(), do: insert(:auction_supplier_coq)

  def create_auction_supplier_coq(auction = %Auction{}, supplier) do
    fuel = auction.auction_vessel_fuels |> List.first() |> Map.get(:fuel)
    insert(:auction_supplier_coq, auction: auction, fuel: fuel, supplier: supplier)
  end

  def create_auction_supplier_coq(auction = %TermAuction{fuel: fuel}, supplier) do
    insert(:auction_supplier_coq, auction: auction, fuel: fuel, supplier: supplier)
  end

  def draft_auction_factory() do
    %Oceanconnect.Auctions.Auction{
      port: build(:port)
    }
  end

  def auction_factory() do
    start =
      DateTime.utc_now()
      |> DateTime.to_naive()
      |> NaiveDateTime.add(20)
      |> DateTime.from_naive!("Etc/UTC")

    struct!(
      draft_auction_factory(),
      %{
        type: "spot",
        scheduled_start: start,
        duration: 10 * 60_000,
        decision_duration: 15 * 60_000,
        auction_vessel_fuels: [build(:vessel_fuel)],
        additional_information: "",
        buyer: build(:company),
        suppliers: [build(:company, is_supplier: true)]
      }
    )
  end

  def draft_term_auction_factory() do
    start_date =
      DateTime.utc_now()
      |> DateTime.to_naive()
      |> NaiveDateTime.add(20)
      |> DateTime.from_naive!("Etc/UTC")

    end_date =
      DateTime.utc_now()
      |> DateTime.to_naive()
      |> NaiveDateTime.add(80)
      |> DateTime.from_naive!("Etc/UTC")

    %Oceanconnect.Auctions.TermAuction{
      port: build(:port),
      fuel: build(:fuel),
      start_date: start_date,
      end_date: end_date
    }
  end

  def term_auction_factory() do
    start_time =
      DateTime.utc_now()
      |> DateTime.to_naive()
      |> NaiveDateTime.add(20)
      |> DateTime.from_naive!("Etc/UTC")

    struct!(
      draft_term_auction_factory(),
      %{
        type: "forward_fixed",
        scheduled_start: start_time,
        fuel_quantity: 1500,
        terminal: "TERMINAL",
        duration: 10 * 60_000,
        buyer: build(:company),
        additional_information: "",
        suppliers: [build(:company, is_supplier: true)]
      }
    )
  end

  def formula_related_auction_factory() do
    start_time =
      DateTime.utc_now()
      |> DateTime.to_naive()
      |> NaiveDateTime.add(20)
      |> DateTime.from_naive!("Etc/UTC")

    struct!(
      draft_term_auction_factory(),
      %{
        type: "formula_related",
        current_index_price: 750.00,
        scheduled_start: start_time,
        fuel_index: build(:fuel_index),
        fuel_quantity: 1500,
        terminal: "TERMINAL",
        duration: 10 * 60_000,
        buyer: build(:company),
        suppliers: [build(:company, is_supplier: true)]
      }
    )
  end

  def vessel_fuel_factory() do
    %Oceanconnect.Auctions.AuctionVesselFuel{
      vessel: build(:vessel),
      fuel: build(:fuel),
      quantity: 1500,
      eta: DateTime.utc_now(),
      etd: DateTime.utc_now()
    }
  end

  def fuel_factory() do
    %Oceanconnect.Auctions.Fuel{
      name: sequence(:name, &"New Fuel #{&1}")
    }
  end

  def fuel_index_factory() do
    %Oceanconnect.Auctions.FuelIndex{
      name: sequence(:name, &"New Fuel Index #{&1}"),
      code: "1234",
      fuel: build(:fuel),
      port: build(:port)
    }
  end

  def port_factory() do
    %Oceanconnect.Auctions.Port{
      name: "New Port",
      country: "Timbuktu"
    }
  end

  def barge_factory() do
    %Oceanconnect.Auctions.Barge{
      companies: [build(:company, is_supplier: true)],
      port: build(:port),
      name: sequence(:barge_name, &"Barge-#{&1}")
    }
  end

  def barge_with_no_supplier_factory() do
    %Oceanconnect.Auctions.Barge{
      port: build(:port),
      name: sequence(:barge_name, &"Barge-#{&1}")
    }
  end

  def auction_barge_factory() do
    %Oceanconnect.Auctions.AuctionBarge{
      auction: build(:auction),
      barge: build(:barge),
      supplier: build(:company, is_supplier: true),
      approval_status: "PENDING"
    }
  end

  def vessel_factory() do
    %Oceanconnect.Auctions.Vessel{
      imo: 1_234_567,
      name: sequence(:vessel_name, &"Vessel-#{&1}"),
      company: build(:company)
    }
  end

  def message_factory() do
    company = build(:company)

    %Oceanconnect.Messages.Message{
      auction: build(:auction),
      content: "Hi!",
      has_been_seen: false,
      author: build(:user, company: company),
      author_company: company,
      recipient_company: build(:company)
    }
  end

  def auction_fixture_factory() do
    %Oceanconnect.Auctions.AuctionFixture{
      auction: build(:auction, finalized: true, auction_closed_time: DateTime.utc_now()),
      supplier: build(:company, is_supplier: true),
      vessel: build(:vessel),
      fuel: build(:fuel),
      original_supplier: build(:company, is_supplier: true),
      original_vessel: build(:vessel),
      original_fuel: build(:fuel)
    }
  end

  def claim_factory() do
    %Oceanconnect.Deliveries.Claim{
      type: "quantity",
      closed: false,
      quantity_missing: 100,
      price_per_unit: 100,
      total_fuel_value: 10_000,
      supplier: build(:company, is_supplier: true),
      receiving_vessel: build(:vessel),
      delivered_fuel: build(:fuel),
      delivering_barge: build(:barge),
      additional_information: "Your fuel sucked!",
      notice_recipient_type: "supplier",
      notice_recipient: build(:company, is_supplier: true),
      auction: build(:auction),
      fixture: build(:auction_fixture)
    }
  end

  def claim_response_factory() do
    %Oceanconnect.Deliveries.ClaimResponse{
      author: build(:user),
      claim: build(:claim),
      content: "I don't care what you say!"
    }
  end

  def create_bid(amount, min_amount, supplier_id, vessel_fuel_id, auction, is_traded_bid \\ false) do
    bid_params = %{
      "amount" => amount,
      "comment" => "test bid",
      "min_amount" => min_amount,
      "supplier_id" => supplier_id,
      "vessel_fuel_id" => "#{vessel_fuel_id}",
      "is_traded_bid" => is_traded_bid,
      "allow_split" => true,
      "time_entered" => DateTime.utc_now()
    }

    Oceanconnect.Auctions.AuctionBid.from_params_to_auction_bid(bid_params, auction)
  end

  def start_auction!(auction) do
    initial_state = Oceanconnect.Auctions.AuctionStore.AuctionState.from_auction(auction)
    command = Command.start_auction(auction, DateTime.utc_now(), nil)
    {:ok, events} = Aggregate.process(initial_state, command)
    Enum.map(events, &AuctionEventStore.persist/1)
  end

  def cancel_auction!(auction) do
    initial_state = Oceanconnect.Auctions.AuctionStore.AuctionState.from_auction(auction)
    command = Command.cancel_auction(auction, DateTime.utc_now(), nil)
    {:ok, events} = Aggregate.process(initial_state, command)
    Enum.map(events, &AuctionEventStore.persist/1)
  end

  def expire_auction!(auction) do
    initial_state = Oceanconnect.Auctions.AuctionStore.AuctionState.from_auction(auction)

    [
      Command.start_auction(auction, DateTime.utc_now(), nil),
      Command.end_auction(auction, DateTime.utc_now()),
      Command.end_auction_decision_period(auction, DateTime.utc_now())
    ]
    |> Enum.reduce(initial_state, fn command, state ->
      {:ok, events} = Aggregate.process(state, command)
      Enum.map(events, &AuctionEventStore.persist/1)

      events
      |> Enum.reduce(state, fn event, state ->
        {:ok, state} = Aggregate.apply(state, event)
        state
      end)
    end)
  end

  def close_auction!(auction = %Auction{suppliers: suppliers}) do
    supplier_id = hd(suppliers).id
    vessel_fuel_id = hd(auction.auction_vessel_fuels).id
    bid = create_bid(3.50, 3.50, supplier_id, vessel_fuel_id, auction)
    solution = %Solution{bids: [bid]}
    initial_state = Oceanconnect.Auctions.AuctionStore.AuctionState.from_auction(auction)

    [
      Command.start_auction(auction, DateTime.utc_now(), nil),
      Command.process_new_bid(bid, nil),
      Command.end_auction(auction, DateTime.utc_now()),
      Command.select_winning_solution(solution, auction, DateTime.utc_now(), "Smith", nil)
    ]
    |> Enum.reduce(initial_state, fn command, state ->
      {:ok, events} = Aggregate.process(state, command)
      Enum.map(events, &AuctionEventStore.persist/1)

      events
      |> Enum.reduce(state, fn event, state ->
        {:ok, state} = Aggregate.apply(state, event)
        state
      end)
    end)
  end
end
