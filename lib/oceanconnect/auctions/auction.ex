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
    field :eta, :naive_datetime
    field :etd, :naive_datetime
    field :auction_start, :naive_datetime
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
    try do
      %{^key => date} = params
      updated_date = parse_date(date)
      Map.put(params, key, updated_date)
     rescue
        _ ->
          Map.delete(params, key)
     end
  end

  def parse_date(%{"date" => date, "hour" =>  hour, "minute" => min}) do
    parse_date(date, hour, min)
  end

  def parse_date(epoch) do
    epoch
    |> String.to_integer
    |> DateTime.from_unix!(:milliseconds)
    |> DateTime.to_naive
    |> NaiveDateTime.to_string
  end
  def parse_date(date, hour, min) when date == "" or hour == "" or min == "", do: nil
  def parse_date(date, hour, min) do
    [day, month, year] = date
    |> String.split("/")
    |> Enum.map(fn(int) ->
      String.to_integer(int)
    end)

    {:ok, date} = NaiveDateTime.new(year, month, day, String.to_integer(hour), String.to_integer(min), 0)
    NaiveDateTime.to_string(date)
  end
end
