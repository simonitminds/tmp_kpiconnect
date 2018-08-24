defmodule Oceanconnect.Auctions.Auction do
  import Ecto.Query
  use Ecto.Schema
  import Ecto.Changeset
  alias Oceanconnect.Auctions.{Auction, Port, Vessel, Fuel}

  @derive {Poison.Encoder, except: [:__meta__, :auction_suppliers]}
  schema "auctions" do
    belongs_to(:port, Port)
    belongs_to(:vessel, Vessel)
    belongs_to(:fuel, Fuel)
    belongs_to(:buyer, Oceanconnect.Accounts.Company)
    field(:fuel_quantity, :integer)
    field(:po, :string)
    field(:port_agent, :string)
    field(:eta, :utc_datetime)
    field(:etd, :utc_datetime)
    field(:scheduled_start, :utc_datetime)
    field(:auction_ended, :utc_datetime)
    # milliseconds
    field(:duration, :integer, default: 10 * 60_000)
    # milliseconds
    field(:decision_duration, :integer, default: 15 * 60_000)
    field(:anonymous_bidding, :boolean)
    field(:additional_information, :string)

    many_to_many(
      :suppliers,
      Oceanconnect.Accounts.Company,
      join_through: Oceanconnect.Auctions.AuctionSuppliers,
      join_keys: [auction_id: :id, supplier_id: :id],
      on_replace: :delete,
      on_delete: :delete_all
    )

    has_many(:auction_suppliers, Oceanconnect.Auctions.AuctionSuppliers)

    timestamps()
  end

  @required_fields [
    :eta,
    :port_id,
    :vessel_id
  ]

  @optional_fields [
    :buyer_id,
    :additional_information,
    :anonymous_bidding,
    :scheduled_start,
    :auction_ended,
    :duration,
    :decision_duration,
    :etd,
    :fuel_id,
    :fuel_quantity,
    :po,
    :port_agent
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

  def changeset_for_scheduled_auction(%Auction{} = auction, attrs) do
    auction
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields ++ [:scheduled_start, :fuel_id, :fuel_quantity])
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
    |> maybe_parse_date_field("scheduled_start")
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

      _ ->
        params
    end
  end

  def maybe_convert_duration(params, key) do
    case params do
      %{^key => duration} ->
        updated_duration = parse_duration(duration) * 60_000
        Map.put(params, key, updated_duration)

      _ ->
        params
    end
  end

  def maybe_load_suppliers(params, "suppliers") do
    case params do
      %{"suppliers" => suppliers} ->
        supplier_ids =
          Enum.map(suppliers, fn {_key, supplier_id} -> String.to_integer(supplier_id) end)

        query =
          from(
            c in Oceanconnect.Accounts.Company,
            where: c.id in ^supplier_ids
          )

        Map.put(params, "suppliers", Oceanconnect.Repo.all(query))

      _ ->
        params
    end
  end

  defp parse_duration(duration) when is_binary(duration), do: String.to_integer(duration)
  defp parse_duration(duration) when is_integer(duration), do: duration

  def parse_date(""), do: ""

  def parse_date(epoch) do
    epoch
    |> String.to_integer()
    |> DateTime.from_unix!(:milliseconds)
    |> DateTime.to_string()
  end

  def select_upcoming(query \\ Auction, time_frame) do
    current_time = DateTime.utc_now()
    from q in query,
      where: fragment("? - ?", q.scheduled_start, ^current_time) >= 0 and fragment("? - ?", q.sheduled_start, ^current_time) <= ^time_frame
  end
end
