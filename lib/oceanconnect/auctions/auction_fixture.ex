defmodule Oceanconnect.Auctions.AuctionFixture do
  use Ecto.Schema
  import Ecto.Query, warn: false
  import Ecto.Changeset
  import Oceanconnect.Auctions.Guards
  alias __MODULE__
  alias Oceanconnect.Auctions.{AuctionVesselFuel, AuctionBid}

  @derive {Poison.Encoder,
           except: [:__meta__, :auction, :original_vessel, :original_fuel, :original_supplier]}
  schema "auction_fixtures" do
    # current_relationships
    # TODO: virtualize auction to work with term auctions
    belongs_to(:auction, Oceanconnect.Auctions.Auction)
    belongs_to(:supplier, Oceanconnect.Accounts.Company)
    belongs_to(:vessel, Oceanconnect.Auctions.Vessel)
    belongs_to(:fuel, Oceanconnect.Auctions.Fuel)

    # current fields
    field(:price, :decimal)
    field(:quantity, :integer)
    field(:eta, :utc_datetime_usec)
    field(:etd, :utc_datetime_usec)
    field(:delivered, :boolean, default: false)
    field(:comment, :string, virtual: true)

    # original_relationships
    belongs_to(:original_supplier, Oceanconnect.Accounts.Company,
      foreign_key: :original_supplier_id
    )

    belongs_to(:original_vessel, Oceanconnect.Auctions.Vessel, foreign_key: :original_vessel_id)
    belongs_to(:original_fuel, Oceanconnect.Auctions.Fuel, foreign_key: :original_fuel_id)

    # original_fields
    field(:original_quantity, :integer)
    field(:original_eta, :utc_datetime_usec)
    field(:original_etd, :utc_datetime_usec)
    field(:original_price, :decimal)
  end

  def update_changeset(%AuctionFixture{} = auction_fixture, attrs) do
    auction_fixture
    |> cast(attrs, [
      :auction_id,
      :supplier_id,
      :vessel_id,
      :fuel_id,
      :price,
      :quantity,
      :eta,
      :etd,
      :comment
    ])
    |> validate_required([
      :auction_id,
      :supplier_id,
      :fuel_id,
      :price,
      :quantity,
      :eta
    ])
    |> foreign_key_constraint(:auction_id)
    |> foreign_key_constraint(:supplier_id)
    |> foreign_key_constraint(:fuel_id)
    |> foreign_key_constraint(:vessel_id)
  end

  def deliver_changeset(%AuctionFixture{} = fixture, attrs) do
    fixture
    |> cast(attrs, [:delivered])
  end

  def changeset(%AuctionFixture{} = auction_fixture, attrs) do
    auction_fixture
    |> cast(attrs, [
      :auction_id,
      :supplier_id,
      :vessel_id,
      :fuel_id,
      :price,
      :quantity,
      :eta,
      :etd,
      :original_supplier_id,
      :original_vessel_id,
      :original_fuel_id,
      :original_price,
      :original_quantity,
      :original_eta,
      :original_etd
    ])
    |> validate_required([
      :auction_id,
      :supplier_id,
      :vessel_id,
      :fuel_id,
      :price,
      :quantity,
      :eta,
      :original_supplier_id,
      :original_vessel_id,
      :original_fuel_id,
      :original_price,
      :original_quantity,
      :original_eta
    ])
    |> foreign_key_constraint(:auction_id)
    |> foreign_key_constraint(:supplier_id)
    |> foreign_key_constraint(:fuel_id)
    |> foreign_key_constraint(:vessel_id)
    |> foreign_key_constraint(:original_supplier_id)
    |> foreign_key_constraint(:original_fuel_id)
    |> foreign_key_constraint(:original_vessel_id)
  end

  def for_auction_vessel_fuel(%AuctionVesselFuel{
        auction_id: auction_id,
        vessel_id: vessel_id,
        fuel_id: fuel_id
      }) do
    from(af in AuctionFixture,
      where:
        af.vessel_id == ^vessel_id and af.fuel_id == ^fuel_id and af.auction_id == ^auction_id
    )
  end

  def from_auction(%struct{id: auction_id}) when is_auction(struct) do
    from(af in AuctionFixture,
      where: af.auction_id == ^auction_id
    )
  end

  def changeset_from_bid_and_vessel_fuel(
        %AuctionBid{
          amount: amount,
          supplier_id: supplier_id,
          auction_id: auction_id
        },
        %AuctionVesselFuel{
          vessel_id: vessel_id,
          fuel_id: fuel_id,
          eta: eta,
          etd: etd,
          quantity: quantity
        }
      ) do
    %AuctionFixture{}
    |> changeset(%{
      auction_id: auction_id,
      supplier_id: supplier_id,
      vessel_id: vessel_id,
      fuel_id: fuel_id,
      price: amount,
      quantity: quantity,
      eta: eta,
      etd: etd,
      original_supplier_id: supplier_id,
      original_vessel_id: vessel_id,
      original_fuel_id: fuel_id,
      original_price: amount,
      original_quantity: quantity,
      original_eta: eta,
      original_etd: etd
    })
  end
end
