defmodule Oceanconnect.Auctions.Auction do
  use Ecto.Schema
  import Ecto.Changeset
  alias Oceanconnect.Auctions.{Auction, Port, Vessel, Fuel}

  @derive {Poison.Encoder, except: [:__meta__]}
  schema "auctions" do
    belongs_to :port, Port
    belongs_to :vessel, Vessel
    belongs_to :fuel, Fuel
    field :fuel_quantity, :integer
    field :company, :string
    field :po, :string
    field :eta, :utc_datetime
    field :etd, :utc_datetime
    field :auction_start, :utc_datetime
    field :duration, :integer
    field :anonymous_bidding, :boolean
    field :additional_information, :string

    timestamps()
  end

  @doc false
  def changeset(%Auction{} = auction, attrs) do
    auction
    |> cast(attrs, [:vessel_id, :port_id, :fuel_id, :company, :po, :eta, :etd, :auction_start, :duration, :anonymous_bidding, :fuel_quantity, :additional_information])
    |> cast_assoc(:port)
    |> cast_assoc(:vessel)
    |> cast_assoc(:fuel)
    |> validate_required([:vessel_id, :port_id, :fuel_id])
  end

  def from_params(params) do
    params
    |> maybe_parse_date_field("auction_start")
    |> maybe_parse_date_field("eta")
    |> maybe_parse_date_field("etd")
  end

  def maybe_parse_date_field(params, key) do
    case params do
      %{^key => date} ->
        updated_date = parse_date(date)
        Map.put(params, key, updated_date)
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
