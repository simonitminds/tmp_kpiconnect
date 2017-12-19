defmodule Oceanconnect.Auctions.Auction do
  use Ecto.Schema
  import Ecto.Changeset
  alias Oceanconnect.Auctions.{Auction, Port, Vessel}

  @derive {Poison.Encoder, except: [:__meta__]}
  schema "auctions" do
    # field :port, :string
    belongs_to :port, Port
    belongs_to :vessel, Vessel
    field :company, :string
    field :po, :string
    field :eta, :naive_datetime
    field :etd, :naive_datetime
    field :auction_start, :naive_datetime
    field :duration, :integer
    field :anonymous_bidding, :boolean

    timestamps()
  end

  @doc false
  def changeset(%Auction{} = auction, attrs) do
    auction
    |> cast(attrs, [:vessel_id, :port_id, :company, :po, :eta, :etd, :auction_start, :duration, :anonymous_bidding])
    |> cast_assoc(:port)
    |> cast_assoc(:vessel)
    |> validate_required([:vessel_id, :port_id])
  end

  def from_params(params) do
    params
    |> maybe_parse_date_field("auction_start")
    |> maybe_parse_date_field("eta")
    |> maybe_parse_date_field("etd")
  end

  def maybe_parse_date_field(params, key) do
    try do
       %{^key => %{"date" => date, "hour" =>  hour, "minute" => min}} = params
      updated_date = parse_date(date, hour, min)
      Map.put(params, key, updated_date)
    rescue
       _ -> params
    end
  end

  def parse_date(date, hour, min) when date == "" or hour == "" or min == "", do: nil
  def parse_date(date, hour, min) do
    [year, month, day] = date
    |> String.split("-")
    |> Enum.map(fn(int) ->
      String.to_integer(int)
    end)

    {:ok, date} = NaiveDateTime.new(year, month, day, String.to_integer(hour), String.to_integer(min), 0)
    NaiveDateTime.to_string(date)
  end
end
