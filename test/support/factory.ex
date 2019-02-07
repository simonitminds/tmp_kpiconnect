defmodule Oceanconnect.Factory do
  use ExMachina.Ecto, repo: Oceanconnect.Repo

  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{AuctionFixture, AuctionEvent, AuctionEventStorage, AuctionStateActions}

  def set_password(user) do
    hashed_password = Comeonin.Bcrypt.hashpwsalt(user.password)
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
        scheduled_start: start,
        duration: 10 * 60_000,
        decision_duration: 15 * 60_000,
        auction_vessel_fuels: [build(:vessel_fuel)],
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
      name: "New Fuel"
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
      auction: build(:auction),
      supplier: build(:company, is_supplier: true),
      vessel: build(:vessel),
      fuel: build(:fuel),
      original_supplier: build(:company, is_supplier: true),
      original_vessel: build(:vessel),
      original_fuel: build(:fuel)
    }
  end

  def create_bid(amount, min_amount, supplier_id, vessel_fuel_id, auction, is_traded_bid \\ false) do
    bid_params = %{
      "amount" => amount,
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
    state = Oceanconnect.Auctions.AuctionStore.AuctionState.from_auction(auction)
    next_state = AuctionStateActions.start_auction(state, auction, nil, true)
    event = AuctionEvent.auction_started(auction, next_state, nil)
    AuctionEventStorage.persist(%AuctionEventStorage{event: event})
  end

  def cancel_auction!(auction) do
    state = Oceanconnect.Auctions.AuctionStore.AuctionState.from_auction(auction)
    new_state = AuctionStateActions.cancel_auction(auction, state)

    AuctionEventStorage.persist(%AuctionEventStorage{
      event: AuctionEvent.auction_canceled(auction, new_state, nil)
    })
  end

  def expire_auction!(auction) do
    current_state = Auctions.get_auction_state!(auction)
    new_state = AuctionStateActions.expire_auction(auction, current_state)
    event = AuctionEvent.auction_expired(auction, new_state)
    AuctionEventStorage.persist(%AuctionEventStorage{event: event, auction_id: auction.id})
  end

  def close_auction!(auction) do
    supplier_id = hd(auction.suppliers).id
    vessel_fuel_id = hd(auction.auction_vessel_fuels).id
    bid = create_bid(3.50, 3.50, supplier_id, vessel_fuel_id, auction)
    state = Oceanconnect.Auctions.AuctionStore.AuctionState.from_auction(auction)
    state = AuctionStateActions.start_auction(state, auction, nil, false)
    {_product_state, _events, new_state} = AuctionStateActions.process_bid(state, bid)
    solution = new_state.solutions.best_overall
    state = AuctionStateActions.select_winning_solution(solution, "Smith", auction, new_state)
    event = AuctionEvent.winning_solution_selected(solution, "", state, nil)
    AuctionEventStorage.persist(%AuctionEventStorage{event: event, auction_id: auction.id})
  end
end
