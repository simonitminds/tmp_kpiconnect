defmodule Oceanconnect.Auctions.Auction do
  use Ecto.Schema
  import Ecto.Changeset
  alias Oceanconnect.Auctions.{Auction, Port, Vessel, Fuel}

  @derive {Poison.Encoder, except: [:__meta__]}
  schema "auctions" do
    belongs_to :port, Port
    belongs_to :vessel, Vessel
    belongs_to :fuel, Fuel
    belongs_to :buyer, Oceanconnect.Accounts.User
    field :fuel_quantity, :integer
    field :po, :string
    field :eta, :utc_datetime
    field :etd, :utc_datetime
    field :auction_start, :utc_datetime
    field :duration, :integer # milliseconds
    field :anonymous_bidding, :boolean
    field :additional_information, :string
    many_to_many :suppliers, Oceanconnect.Accounts.User, join_through: Oceanconnect.Auctions.AuctionSuppliers,
      join_keys: [auction_id: :id, supplier_id: :id], on_replace: :delete

    timestamps()
  end

    @required_fields [
      :fuel_id,
      :port_id,
      :vessel_id
    ]

    @optional_fields [
      :buyer_id,
      :additional_information,
      :anonymous_bidding,
      :auction_start,
      :duration,
      :eta,
      :etd,
      :fuel_quantity,
      :po
    ]

  @doc false
  def changeset(%Auction{} = auction, attrs) do
    auction
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> cast_assoc(:buyer)
    |> cast_assoc(:port)
    |> cast_assoc(:vessel)
    |> cast_assoc(:fuel)
  end

  def from_params(params) do
    params
    |> maybe_parse_date_field("auction_start")
    |> maybe_parse_date_field("eta")
    |> maybe_parse_date_field("etd")
    |> maybe_convert_duration("duration")
  end

  def maybe_parse_date_field(params, key) do
    case params do
      %{^key => date} ->
        updated_date = parse_date(date)
        Map.put(params, key, updated_date)
      _ -> params
    end
  end

  def maybe_convert_duration(params, key) do
    case params do
      %{^key => duration} ->
        updated_duration = duration * 60_000
        Map.put(params, key, updated_duration)
      _ -> params
    end
  end

  def parse_date(""), do: ""
  def parse_date(epoch) do
    epoch
    |> String.to_integer
    |> DateTime.from_unix!(:milliseconds)
    |> DateTime.to_string
  end
end
