defmodule Oceanconnect.Auctions.AuctionFixture do
  use Ecto.Schema
  import Ecto.Query, warn: false
  import Ecto.Changeset
  import Oceanconnect.Auctions.Guards
  alias __MODULE__
  alias Oceanconnect.Auctions.{AuctionVesselFuel, AuctionBid}

  @derive {Poison.Encoder,
           except: [:__meta__, :auction, :delivered_supplier, :delivered_fuel, :delivered_vessel]}
  schema "auction_fixtures" do
    # current_relationships
    # TODO: virtualize auction to work with term auctions
    belongs_to(:auction, Oceanconnect.Auctions.Auction)
    belongs_to(:supplier, Oceanconnect.Accounts.Company)
    belongs_to(:vessel, Oceanconnect.Auctions.Vessel)
    belongs_to(:fuel, Oceanconnect.Auctions.Fuel)

    # current fields
    field(:price, :decimal)
    field(:quantity, :decimal)
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
    field(:original_quantity, :decimal)
    field(:original_eta, :utc_datetime_usec)
    field(:original_etd, :utc_datetime_usec)
    field(:original_price, :decimal)

    belongs_to(:delivered_vessel, Oceanconnect.Auctions.Vessel, foreign_key: :delivered_vessel_id)
    belongs_to(:delivered_fuel, Oceanconnect.Auctions.Fuel, foreign_key: :delivered_fuel_id)

    belongs_to(:delivered_supplier, Oceanconnect.Accounts.Company,
      foreign_key: :delivered_supplier_id
    )

    field(:delivered_quantity, :decimal)
    field(:delivered_eta, :utc_datetime_usec)
    field(:delivered_etd, :utc_datetime_usec)
    field(:delivered_price, :decimal)
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
    |> foreign_key_constraint(:claim_id)
  end

  def propose_changeset(%AuctionFixture{} = fixture, attrs) do
    fixture
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
    |> foreign_key_constraint(:auction_id)
    |> foreign_key_constraint(:supplier_id)
    |> foreign_key_constraint(:fuel_id)
    |> foreign_key_constraint(:vessel_id)
    |> foreign_key_constraint(:claim_id)
  end

  def deliver_changeset(%AuctionFixture{} = fixture, attrs) do
    attrs =
      attrs
      |> maybe_parse_date_field()

    fixture
    |> cast(attrs, [
      :delivered,
      :delivered_supplier_id,
      :delivered_vessel_id,
      :delivered_fuel_id,
      :delivered_price,
      :delivered_quantity,
      :delivered_eta,
      :delivered_etd
    ])
    |> foreign_key_constraint(:delivered_supplier_id)
    |> foreign_key_constraint(:delivered_fuel_id)
    |> foreign_key_constraint(:delivered_vessel_id)
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
      :original_etd,
      :delivered_supplier_id,
      :delivered_vessel_id,
      :delivered_fuel_id,
      :delivered_price,
      :delivered_quantity,
      :delivered_eta,
      :delivered_etd
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
    |> foreign_key_constraint(:delivered_supplier_id)
    |> foreign_key_constraint(:delivered_fuel_id)
    |> foreign_key_constraint(:delivered_vessel_id)
    |> foreign_key_constraint(:claim_id)
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

  defp maybe_parse_date_field(
         %{"delivered_eta" => delivered_eta, "delivered_etd" => delivered_etd} = attrs
       ) do
    Map.merge(attrs, %{
      "delivered_eta" => parse_date(delivered_eta),
      "delivered_etd" => parse_date(delivered_etd)
    })
  end

  defp parse_date(""), do: ""
  defp parse_date(nil), do: ""
  defp parse_date(%DateTime{} = date), do: date

  defp parse_date(epoch) do
    epoch
    |> String.to_integer()
    |> DateTime.from_unix!(:millisecond)
    |> DateTime.to_iso8601()
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
      original_etd: etd,
      delivered_supplier_id: supplier_id,
      delivered_vessel_id: vessel_id,
      delivered_fuel_id: fuel_id,
      delivered_price: amount,
      delivered_quantity: quantity,
      delivered_eta: eta,
      delivered_etd: etd,
    })
  end

end
