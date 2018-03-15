defmodule Oceanconnect.Auctions.Auction do
  import Ecto.Query
  use Ecto.Schema
  import Ecto.Changeset
  alias Oceanconnect.Auctions.{Auction, Port, Vessel, Fuel}

  @current_time_trunc %DateTime{DateTime.utc_now() | hour: 0, minute: 0, second: 0}

  @derive {Poison.Encoder, except: [:__meta__]}
  schema "auctions" do
    belongs_to :port, Port
    belongs_to :vessel, Vessel
    belongs_to :fuel, Fuel
    belongs_to :buyer, Oceanconnect.Accounts.Company
    field :fuel_quantity, :integer
    field :po, :string
    field :eta, :utc_datetime, default: @current_time_trunc
    field :etd, :utc_datetime, default: @current_time_trunc
    field :auction_start, :utc_datetime, default: @current_time_trunc
    field :duration, :integer, default: 10 * 60_000 # milliseconds
    field :decision_duration, :integer, default: 15 * 60_000 # milliseconds
    field :anonymous_bidding, :boolean
    field :additional_information, :string
    many_to_many :suppliers, Oceanconnect.Accounts.Company, join_through: Oceanconnect.Auctions.AuctionSuppliers,
      join_keys: [auction_id: :id, supplier_id: :id], on_replace: :delete, on_delete: :delete_all

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
    :decision_duration,
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
    |> maybe_add_suppliers(attrs)
  end

  def maybe_add_suppliers(changeset, %{"suppliers" => suppliers}) do
    put_assoc(changeset, :suppliers, suppliers)
  end
  def maybe_add_suppliers(changeset, %{suppliers: suppliers}) do
    put_assoc(changeset, :suppliers, suppliers)
  end
  def maybe_add_suppliers(changeset, _attrs), do: changeset

  def from_params(params) do
    params
    |> maybe_parse_date_field("auction_start")
    |> maybe_parse_date_field("eta")
    |> maybe_parse_date_field("etd")
    |> maybe_convert_duration("duration")
    |> maybe_convert_duration("decision_duration")
    |> maybe_load_suppliers("suppliers")
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
        updated_duration = parse_duration(duration) * 60_000
        Map.put(params, key, updated_duration)
      _ -> params
    end
  end

  def maybe_load_suppliers(params, "suppliers") do
    case params do
      %{"suppliers" => suppliers} ->
        supplier_ids = Enum.map(suppliers, fn({_key, supplier_id}) -> String.to_integer(supplier_id) end)
        query = from c in Oceanconnect.Accounts.Company,
          where: c.id in ^supplier_ids
        Map.put(params, "suppliers", Oceanconnect.Repo.all(query))
      _ -> params
    end
  end

  defp parse_duration(duration) when is_binary(duration), do: String.to_integer(duration)
  defp parse_duration(duration) when is_integer(duration), do: duration

  def parse_date(""), do: ""
  def parse_date(epoch) do
    epoch
    |> String.to_integer
    |> DateTime.from_unix!(:milliseconds)
    |> DateTime.to_string
  end
end
