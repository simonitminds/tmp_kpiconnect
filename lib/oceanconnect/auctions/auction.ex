defmodule Oceanconnect.Auctions.Auction do
  use Ecto.Schema
  import Ecto.Changeset
  alias Oceanconnect.Auctions.Auction

  schema "auctions" do
    field :port, :string
    field :vessel, :string
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
    |> cast(attrs, [:vessel, :port, :company, :po, :eta, :etd, :auction_start, :duration, :anonymous_bidding])
    |> validate_required([:vessel, :port])
  end

  def from_params(params) do
    params
    |> maybe_parse_auction_start
    |> maybe_parse_etd
    |> maybe_parse_eta
    #
    # params
    # |> maybe_add_auction_start
    # |> maybe_add_etd
    # |> maybe_add_eta
  end

  # def maybe_add_auction_start(params = %{"auction_start" => %{"date" => date }}) do
  #   [year, month, day] = date |> String.split("-") |> Enum.map(&(String.to_integer(&1)))
  #   params
  #   |> put_in(["auction_start", :year], Integer.to_string(year))
  #   |> put_in(["auction_start", :month], Integer.to_string(month))
  #   |> put_in(["auction_start", :day], Integer.to_string(day))
  # end
  #
  # def maybe_add_etd(params = %{"etd" => %{"date" => date }}) do
  #   [year, month, day] = date |> String.split("-") |> Enum.map(&(String.to_integer(&1)))
  #   params
  #   |> put_in(["etd", :year], Integer.to_string(year))
  #   |> put_in(["etd", :month], Integer.to_string(month))
  #   |> put_in(["etd", :day], Integer.to_string(day))
  # end
  #
  # def maybe_add_eta(params = %{"eta" => %{"date" => date }}) do
  #   [year, month, day] = date |> String.split("-") |> Enum.map(&(String.to_integer(&1)))
  #   params
  #   |> put_in(["eta", :year], Integer.to_string(year))
  #   |> put_in(["eta", :month], Integer.to_string(month))
  #   |> put_in(["eta", :day], Integer.to_string(day))
  # end



  def maybe_parse_auction_start(params = %{"auction_start" => %{"date" => date, "hour" => hour, "minute" => min}}) do
    updated_date = parse_date(date, hour, min)
    Map.put(params, "auction_start", updated_date)
  end

  def maybe_parse_etd(params = %{"etd" => %{"date" => date, "hour" => hour, "minute" => min}}) do
    updated_date = parse_date(date, hour, min)
    Map.put(params, "etd", updated_date)
  end
  def maybe_parse_eta(params = %{"eta" => %{"date" => date, "hour" => hour, "minute" => min}}) do
    updated_date = parse_date(date, hour, min)
    Map.put(params, "eta", updated_date)
  end

  def parse_date(date, hour, min) do
    [year, month, day] = date |> String.split("-") |> Enum.map(&(String.to_integer(&1)))
    {:ok, date} = NaiveDateTime.new(year, month, day, String.to_integer(hour), String.to_integer(min), 0)
    NaiveDateTime.to_string(date)
  end

   def start_date_from_params(%{"auction_start" => %{"date" => date, "hour" => hour, "minute" => min}}) do
    [year, month, day] = date |> String.split("-") |> Enum.map(&(String.to_integer(&1)))
    {:ok, date} = NaiveDateTime.new(year, month, day, String.to_integer(hour), String.to_integer(min), 0)
    date
  end
end
