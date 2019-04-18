defmodule Oceanconnect.Auctions.TermAuction do
  import Ecto.Query
  use Ecto.Schema
  import Ecto.Changeset
  alias Oceanconnect.Auctions.{TermAuction, Fuel, FuelIndex, Port, Vessel, TermAuctionVessel}

  @derive {Poison.Encoder, except: [:__meta__, :auction_suppliers, :term_auction_vessels]}
  schema "auctions" do
    field(:type, :string)
    field(:start_date, :utc_datetime_usec, source: :start_date)
    field(:end_date, :utc_datetime_usec, source: :end_date)
    field(:terminal, :string, source: :terminal)

    field(:po, :string)
    field(:port_agent, :string)
    field(:scheduled_start, :utc_datetime_usec)
    field(:auction_started, :utc_datetime_usec)
    field(:auction_ended, :utc_datetime_usec)
    field(:auction_closed_time, :utc_datetime_usec)
    field(:duration, :integer, default: 10 * 60_000)
    field(:decision_duration, :integer, default: 15 * 60_000)
    field(:anonymous_bidding, :boolean)
    field(:is_traded_bid_allowed, :boolean)
    field(:additional_information, :string)

    belongs_to(:port, Port)
    belongs_to(:buyer, Oceanconnect.Accounts.Company)
    belongs_to(:fuel, Fuel)
    belongs_to(:fuel_index, FuelIndex)
    field(:current_index_price, :float, default: nil)
    field(:fuel_quantity, :integer)
    field(:total_fuel_volume, :integer)
    field(:show_total_fuel_volume, :boolean, default: true)

    has_many(:term_auction_vessels, TermAuctionVessel,
      foreign_key: :auction_id,
      on_replace: :delete,
      on_delete: :delete_all
    )

    many_to_many(
      :vessels,
      Vessel,
      join_through: TermAuctionVessel,
      join_keys: [auction_id: :id, vessel_id: :id],
      on_replace: :delete,
      on_delete: :delete_all
    )

    many_to_many(
      :suppliers,
      Oceanconnect.Accounts.Company,
      join_through: Oceanconnect.Auctions.AuctionSuppliers,
      join_keys: [term_auction_id: :id, supplier_id: :id],
      on_replace: :delete,
      on_delete: :delete_all
    )

    has_many(:auction_suppliers, Oceanconnect.Auctions.AuctionSuppliers)

    timestamps()
  end

  @required_fields [
    :type,
    :port_id,
    :fuel_id
  ]

  @optional_fields [
    :additional_information,
    :anonymous_bidding,
    :auction_ended,
    :auction_closed_time,
    :auction_started,
    :buyer_id,
    :current_index_price,
    :duration,
    :decision_duration,
    :end_date,
    :fuel_index_id,
    :fuel_quantity,
    :total_fuel_volume,
    :show_total_fuel_volume,
    :is_traded_bid_allowed,
    :po,
    :port_agent,
    :scheduled_start,
    :start_date,
    :terminal
  ]

  @doc false
  def changeset(%TermAuction{} = auction, attrs) do
    auction
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> cast_assoc(:buyer)
    |> cast_assoc(:port)
    |> cast_assoc(:fuel)
    |> validate_scheduled_start(attrs)
    |> validate_term_period(attrs)
    |> maybe_add_suppliers(attrs)
    |> maybe_add_vessels(attrs)
  end

  def changeset_for_scheduled_auction(%TermAuction{} = auction, attrs) do
    auction
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(
      @required_fields ++ [:scheduled_start, :fuel_quantity, :start_date, :end_date],
      message: "This field is required."
    )
    |> maybe_require_fuel_index()
    |> cast_assoc(:buyer)
    |> cast_assoc(:port)
    |> cast_assoc(:fuel)
    |> cast_assoc(:fuel_index)
    |> validate_scheduled_start(attrs)
    |> validate_term_period(attrs)
    |> maybe_add_suppliers(attrs)
    |> maybe_add_vessels(attrs)
    |> validate_suppliers(auction, attrs)
  end

  def maybe_require_fuel_index(
        %Ecto.Changeset{
          valid?: true,
          changes: %{type: "formula_related"}
        } = changeset
      ) do
    changeset
    |> validate_required(:fuel_index_id, message: "This field is required.")
  end

  def maybe_require_fuel_index(changeset), do: changeset

  def validate_suppliers(
        %Ecto.Changeset{action: action} = changeset,
        %TermAuction{suppliers: suppliers},
        attrs
      )
      when length(suppliers) == 0 do
    cond do
      Map.has_key?(attrs, :suppliers) or Map.has_key?(attrs, "suppliers") ->
        changeset

      !Map.has_key?(attrs, :suppliers) and !Map.has_key?(attrs, "suppliers") ->
        changeset
        |> add_error(:suppliers, "Must invite suppliers to schedule a pending auction")
    end
  end

  def validate_suppliers(changeset, _auction, _attrs), do: changeset

  def maybe_add_suppliers(changeset, %{"suppliers" => suppliers}) do
    put_assoc(changeset, :suppliers, suppliers)
  end

  def maybe_add_suppliers(changeset, %{suppliers: suppliers}) do
    put_assoc(changeset, :suppliers, suppliers)
  end

  def maybe_add_suppliers(changeset, _attrs), do: changeset

  def maybe_add_vessels(changeset, %{"vessels" => vessels}) do
    put_assoc(changeset, :vessels, vessels)
  end

  def maybe_add_vessels(changeset, %{vessels: vessels}) do
    put_assoc(changeset, :vessels, vessels)
  end

  def maybe_add_vessels(changeset, _attrs), do: changeset

  def from_params(params) do
    params
    |> maybe_parse_date_field("scheduled_start")
    |> maybe_parse_date_field("start_date")
    |> maybe_parse_date_field("end_date")
    |> maybe_convert_checkbox("is_traded_bid_allowed")
    |> maybe_convert_checkbox("anonymous_bidding")
    |> maybe_convert_checkbox("show_total_fuel_volume")
    |> maybe_convert_duration("duration")
    |> maybe_convert_duration("decision_duration")
    |> maybe_load_suppliers("suppliers")
    |> maybe_load_vessels("vessels")
  end

  def maybe_convert_checkbox(params, key) do
    case params do
      %{^key => value} ->
        if value == "on" || value == true || value == "true" do
          Map.put(params, key, true)
        else
          Map.put(params, key, false)
        end

      _ ->
        params
    end
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

  def maybe_load_vessels(params, "vessels") do
    case params do
      %{"vessels" => vessels} ->
        vessel_ids = Enum.map(vessels, fn {vessel_id, _data} -> String.to_integer(vessel_id) end)

        query =
          from(
            v in Oceanconnect.Auctions.Vessel,
            where: v.id in ^vessel_ids
          )

        Map.put(params, "vessels", Oceanconnect.Repo.all(query))

      _ ->
        params
    end
  end

  defp parse_duration(duration) when is_binary(duration), do: String.to_integer(duration)
  defp parse_duration(duration) when is_integer(duration), do: duration

  def parse_date(dt = %DateTime{}), do: dt
  def parse_date(""), do: ""
  def parse_date(nil), do: ""

  def parse_date(epoch) do
    epoch
    |> String.to_integer()
    |> DateTime.from_unix!(:millisecond)
    |> DateTime.to_iso8601()
  end

  def select_upcoming(query \\ TermAuction, time_frame) do
    current_time = DateTime.utc_now()

    from(
      q in query,
      where:
        fragment("? - ?", q.scheduled_start, ^current_time) >= 0 and
          fragment("? - ?", q.sheduled_start, ^current_time) <= ^time_frame
    )
  end

  defp validate_scheduled_start(changeset, %{scheduled_start: scheduled_start}) do
    scheduled_start = maybe_convert_time(scheduled_start)
    compare_time(changeset, scheduled_start)
  end

  defp validate_scheduled_start(changeset, %{"scheduled_start" => scheduled_start}) do
    scheduled_start = maybe_convert_time(scheduled_start)
    compare_time(changeset, scheduled_start)
  end

  defp validate_scheduled_start(changeset, _attrs), do: changeset

  defp validate_term_period(changeset, %{start_date: start_date, end_date: end_date}) do
    start_date = maybe_convert_time(start_date)
    end_date = maybe_convert_time(end_date)
    compare_time(changeset, start_date, end_date)
  end

  defp validate_term_period(changeset, %{"start_date" => start_date, "end_date" => end_date}) do
    start_date = maybe_convert_time(start_date)
    end_date = maybe_convert_time(end_date)
    compare_time(changeset, start_date, end_date)
  end

  defp validate_term_period(changeset, _attrs), do: changeset

  defp compare_time(changeset, nil), do: changeset
  defp compare_time(changeset, nil, nil), do: changeset

  defp compare_time(changeset, start_time) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    case DateTime.compare(start_time, now) do
      :lt ->
        add_error(changeset, :scheduled_start, "Auction cannot be scheduled in the past")

      _ ->
        changeset
    end
  end

  defp compare_time(changeset, start_date, end_date) do
    case DateTime.compare(end_date, start_date) do
      :lt ->
        changeset
        |> add_error(:end_date, "End month cannot be before the start month")

      _ ->
        changeset
    end
  end

  defp maybe_convert_time(""), do: nil

  defp maybe_convert_time(time) when is_binary(time) do
    {_, time, _} = DateTime.from_iso8601(time)
    time
  end

  defp maybe_convert_time(time) do
    time
  end
end
