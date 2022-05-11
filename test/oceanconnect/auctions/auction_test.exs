defmodule Oceanconnect.AuctionTest do
  use Oceanconnect.DataCase, async: true
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.Auction

  setup do
    auction = insert(:auction) |> Auctions.fully_loaded()
    term_auction = insert(:term_auction) |> Auctions.fully_loaded()
    finalized_auction = insert(:auction, finalized: true) |> Auctions.fully_loaded()
    finalized_term_auction = insert(:term_auction, finalized: true) |> Auctions.fully_loaded()

    port = insert(:port)
    vessel = insert(:vessel)
    fuel = insert(:fuel)

    auction_attrs = params_for(:auction, port: port)
    term_auction_attrs = params_for(:term_auction, port: port, fuel: fuel)

    invalid_start_time =
      DateTime.utc_now()
      |> DateTime.to_unix()
      |> Kernel.-(60_000)
      |> DateTime.from_unix!()

    {:ok,
     %{
       auction: Auctions.get_auction!(auction.id),
       term_auction: Auctions.get_auction!(term_auction.id),
       finalized_auction: finalized_auction,
       finalized_term_auction: finalized_term_auction,
       port: port,
       vessel: vessel,
       fuel: fuel,
       auction_attrs: auction_attrs,
       term_auction_attrs: term_auction_attrs,
       invalid_start_time: invalid_start_time
     }}
  end

  test "#maybe_add_vessel_fuels does not require quantity for draft auctions", %{
    port: port,
    vessel: vessel,
    fuel: fuel
  } do
    params = %{
      "port_id" => port.id,
      "scheduled_start" => nil,
      "auction_vessel_fuels" => [
        %{
          "vessel_id" => vessel.id,
          "fuel_id" => fuel.id,
          "quantity" => nil,
          "eta" => DateTime.utc_now()
        }
      ]
    }

    changeset = Auction.changeset(%Auction{}, params)
    assert changeset.valid?
  end

  test "#maybe_add_vessel_fuels is valid with just vessel_ids for draft auctions", %{
    port: port,
    vessel: vessel
  } do
    params = %{
      "port_id" => port.id,
      "scheduled_start" => nil,
      "auction_vessel_fuels" => [
        %{"vessel_id" => vessel.id, "eta" => DateTime.utc_now()}
      ]
    }

    changeset = Auction.changeset(%Auction{}, params)
    assert changeset.valid?
  end

  test "#maybe_add_vessel_fuels is valid with just fuel_ids for draft auctions", %{
    port: port,
    fuel: fuel
  } do
    params = %{
      "port_id" => port.id,
      "scheduled_start" => nil,
      "auction_vessel_fuels" => [
        %{"fuel_id" => fuel.id, "eta" => DateTime.utc_now()}
      ]
    }

    changeset = Auction.changeset(%Auction{}, params)
    assert changeset.valid?
  end

  test "#maybe_add_vessel_fuels is invalid without fuel quantities for scheduled auctions", %{
    port: port,
    vessel: vessel,
    fuel: fuel
  } do
    params = %{
      "port_id" => port.id,
      "scheduled_start" => DateTime.utc_now(),
      "auction_vessel_fuels" => [
        %{
          "vessel_id" => vessel.id,
          "fuel_id" => fuel.id,
          "quantity" => nil,
          "eta" => DateTime.utc_now()
        }
      ]
    }

    changeset = Auction.changeset(%Auction{}, params)
    refute changeset.valid?
  end

  test "#maybe_add_vessel_fuels is invalid without vessel ids for scheduled auctions", %{
    port: port,
    fuel: fuel
  } do
    params = %{
      "port_id" => port.id,
      "scheduled_start" => DateTime.utc_now(),
      "auction_vessel_fuels" => [
        %{
          "vessel_id" => nil,
          "fuel_id" => fuel.id,
          "quantity" => 1500,
          "eta" => DateTime.utc_now()
        }
      ]
    }

    changeset = Auction.changeset(%Auction{}, params)
    refute changeset.valid?
  end

  test "#maybe_add_vessel_fuels is invalid without fuel ids for scheduled auctions", %{
    port: port,
    vessel: vessel
  } do
    params = %{
      "port_id" => port.id,
      "scheduled_start" => DateTime.utc_now(),
      "auction_vessel_fuels" => [
        %{
          "vessel_id" => vessel.id,
          "fuel_id" => nil,
          "quantity" => 1500,
          "eta" => DateTime.utc_now()
        }
      ]
    }

    changeset = Auction.changeset(%Auction{}, params)
    refute changeset.valid?
  end

  test "#maybe_add_vessel_fuels is valid with fuel quantities for scheduled auctions", %{
    port: port,
    vessel: vessel,
    fuel: fuel
  } do
    params = %{
      "port_id" => port.id,
      "scheduled_start" => DateTime.utc_now(),
      "auction_vessel_fuels" => [
        %{
          "vessel_id" => vessel.id,
          "fuel_id" => fuel.id,
          "quantity" => 1500,
          "eta" => DateTime.utc_now()
        }
      ]
    }

    changeset = Auction.changeset(%Auction{}, params)
    assert changeset.valid?
  end

  test "#maybe_convert_duration" do
    params = %{"duration" => "10", "decision_duration" => "15"}
    %{"duration" => duration} = Auction.maybe_convert_duration(params, "duration")

    %{"decision_duration" => decision_duration} =
      Auction.maybe_convert_duration(params, "decision_duration")

    assert duration == 10 * 60_000
    assert decision_duration == 15 * 60_000
  end

  test "#maybe_load_suppliers" do
    supplier = insert(:company, is_supplier: true)
    params = %{"suppliers" => %{"supplier-#{supplier.id}" => "#{supplier.id}"}}
    %{"suppliers" => suppliers} = Auction.maybe_load_suppliers(params, "suppliers")

    assert List.first(suppliers).id == supplier.id
  end

  test "#maybe_parse_date_field" do
    expected_date = DateTime.from_naive!(~N[2017-12-28 01:30:00.000], "Etc/UTC")

    epoch =
      expected_date
      |> DateTime.to_unix(:millisecond)
      |> Integer.to_string()

    params = %{"scheduled_start" => epoch}

    %{"scheduled_start" => parsed_date} =
      Auction.maybe_parse_date_field(params, "scheduled_start")

    assert parsed_date == expected_date |> DateTime.to_iso8601()
  end
end
