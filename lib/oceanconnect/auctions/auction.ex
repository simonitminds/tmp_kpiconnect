defmodule Oceanconnect.Auctions.Auction do
  import Ecto.Query
  use Ecto.Schema
  import Ecto.Changeset
  alias Oceanconnect.Auctions.{Auction, Port, AuctionVesselFuel}

  @derive {Poison.Encoder, except: [:__meta__, :auction_suppliers]}
  schema "auctions" do
    field(:type, :string, default: "spot")

    belongs_to(:port, Port)

    has_many(:auction_vessel_fuels, Oceanconnect.Auctions.AuctionVesselFuel,
      on_replace: :delete,
      on_delete: :delete_all
    )

    many_to_many(
      :vessels,
      Oceanconnect.Auctions.Vessel,
      join_through: Oceanconnect.Auctions.AuctionVesselFuel,
      join_keys: [auction_id: :id, vessel_id: :id],
      on_replace: :delete,
      on_delete: :delete_all
    )

    many_to_many(
      :fuels,
      Oceanconnect.Auctions.Fuel,
      join_through: Oceanconnect.Auctions.AuctionVesselFuel,
      join_keys: [auction_id: :id, fuel_id: :id],
      on_replace: :delete,
      on_delete: :delete_all
    )

    belongs_to(:buyer, Oceanconnect.Accounts.Company)
    field(:po, :string)
    field(:port_agent, :string)
    field(:scheduled_start, :utc_datetime_usec)
    field(:auction_started, :utc_datetime_usec)
    field(:auction_ended, :utc_datetime_usec)
    field(:auction_closed_time, :utc_datetime_usec)
    # milliseconds
    field(:duration, :integer, default: 10 * 60_000)
    # milliseconds
    field(:decision_duration, :integer, default: 15 * 60_000)
    field(:anonymous_bidding, :boolean)
    field(:is_traded_bid_allowed, :boolean)
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
    :type,
    :port_id
  ]

  @optional_fields [
    :additional_information,
    :anonymous_bidding,
    :auction_started,
    :auction_ended,
    :auction_closed_time,
    :buyer_id,
    :decision_duration,
    :duration,
    :is_traded_bid_allowed,
    :po,
    :port_agent,
    :scheduled_start
  ]

  @doc false
  def changeset(%Auction{} = auction, attrs) do
    auction
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> cast_assoc(:buyer)
    |> cast_assoc(:port)
    |> validate_scheduled_start(attrs)
    |> maybe_add_vessel_fuels(auction, attrs)
    |> maybe_add_suppliers(attrs)
  end

  def changeset_for_scheduled_auction(%Auction{} = auction, attrs) do
    auction
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields ++ [:scheduled_start])
    |> cast_assoc(:buyer)
    |> cast_assoc(:port)
    |> validate_scheduled_start(attrs)
    |> validate_vessel_fuels(attrs)
    |> maybe_add_vessel_fuels(auction, attrs)
    |> validate_suppliers(auction, attrs)
    |> maybe_add_suppliers(attrs)
  end

  def validate_suppliers(%Ecto.Changeset{action: action} = changeset, %Auction{suppliers: suppliers}, attrs) when length(suppliers) == 0 do
    cond do
      Map.has_key?(attrs, :suppliers) or Map.has_key?(attrs, "suppliers")->
        changeset
      !Map.has_key?(attrs, :suppliers) and !Map.has_key?(attrs, "suppliers") ->
        changeset
        |> add_error(:suppliers, "Must invite suppliers to schedule a pending auction")
    end
  end

  def validate_suppliers(changeset, _auction, _attrs), do: changeset

  def validate_vessel_fuels(changeset, %{"auction_vessel_fuels" => vessel_fuels}) when is_nil(vessel_fuels) or length(vessel_fuels) == 0 do
    changeset
    |> add_error(:auction_vessel_fuels, "No auction vessel fuels set")
  end

  def validate_vessel_fuels(changeset, _attrs), do: changeset

  def maybe_add_suppliers(changeset, %{"suppliers" => suppliers}) do
    put_assoc(changeset, :suppliers, suppliers)
  end

  def maybe_add_suppliers(changeset, %{suppliers: suppliers}) do
    put_assoc(changeset, :suppliers, suppliers)
  end

  def maybe_add_suppliers(changeset, _attrs), do: changeset

  def maybe_add_vessel_fuels(
        changeset,
        %Auction{auction_vessel_fuels: existing_vessel_fuels},
        %{"auction_vessel_fuels" => auction_vessel_fuels}
      )
      when is_list(existing_vessel_fuels) do
    vessel_fuel_changeset_proc =
      case get_field(changeset, :scheduled_start) do
        nil -> &AuctionVesselFuel.changeset_for_draft/2
        _ -> &AuctionVesselFuel.changeset_for_new/2
      end

    list_of_changesets =
      auction_vessel_fuels
      |> Enum.map(fn avf ->
        existing = find_existing_or_new_vessel_fuel(existing_vessel_fuels, avf)
        vessel_fuel_changeset_proc.(existing, avf)
      end)

    put_assoc(changeset, :auction_vessel_fuels, list_of_changesets)
  end

  def maybe_add_vessel_fuels(changeset, %Auction{}, %{
        "auction_vessel_fuels" => auction_vessel_fuels
      }) do
    vessel_fuel_changeset_proc =
      case get_field(changeset, :scheduled_start) do
        nil -> &AuctionVesselFuel.changeset_for_draft/2
        _ -> &AuctionVesselFuel.changeset_for_new/2
      end

    list_of_changesets =
      auction_vessel_fuels
      |> Enum.map(fn avf ->
        vessel_fuel_changeset_proc.(%AuctionVesselFuel{}, avf)
      end)

    put_assoc(changeset, :auction_vessel_fuels, list_of_changesets)
  end

  def maybe_add_vessel_fuels(changeset, _auction = %{}, %{
        auction_vessel_fuels: auction_vessel_fuels
      }) do
    put_assoc(changeset, :auction_vessel_fuels, auction_vessel_fuels)
  end

  def maybe_add_vessel_fuels(changeset, _auction, _attrs), do: changeset

  defp find_existing_or_new_vessel_fuel(vessel_fuels, %{
         "fuel_id" => fuel_id,
         "vessel_id" => vessel_id
       }) do
    Enum.find(vessel_fuels, %AuctionVesselFuel{}, fn %AuctionVesselFuel{
                                                       fuel_id: vf_fuel_id,
                                                       vessel_id: vf_vessel_id
                                                     } ->
      "#{vf_fuel_id}" == fuel_id && "#{vf_vessel_id}" == vessel_id
    end)
  end

  defp find_existing_or_new_vessel_fuel(_vessel_fuels, _vf), do: %AuctionVesselFuel{}

  def from_params(params) do
    params
    |> maybe_parse_date_field("scheduled_start")
    |> maybe_convert_checkbox("is_traded_bid_allowed")
    |> maybe_convert_checkbox("anonymous_bidding")
    |> maybe_convert_duration("duration")
    |> maybe_convert_duration("decision_duration")
    |> maybe_load_suppliers("suppliers")
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

  def select_upcoming(query \\ Auction, time_frame) do
    current_time = DateTime.utc_now()

    from(
      q in query,
      where:
        fragment("? - ?", q.scheduled_start, ^current_time) >= 0 and
          fragment("? - ?", q.sheduled_start, ^current_time) <= ^time_frame
    )
  end

  defp validate_scheduled_start(changeset, %{scheduled_start: scheduled_start}) do
    scheduled_start = maybe_convert_start_time(scheduled_start)
    compare_start_time(changeset, scheduled_start)
  end

  defp validate_scheduled_start(changeset, %{"scheduled_start" => scheduled_start}) do
    scheduled_start = maybe_convert_start_time(scheduled_start)
    compare_start_time(changeset, scheduled_start)
  end

  defp validate_scheduled_start(changeset, _attrs), do: changeset

  defp compare_start_time(changeset, nil), do: changeset

  defp compare_start_time(changeset, start_time) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    case DateTime.compare(start_time, now) do
      :lt ->
        add_error(changeset, :scheduled_start, "Auction cannot be scheduled in the past")

      _ ->
        changeset
    end
  end

  defp maybe_convert_start_time(""), do: nil

  defp maybe_convert_start_time(scheduled_start) when is_binary(scheduled_start) do
    {_, scheduled_start, _} = DateTime.from_iso8601(scheduled_start)
    scheduled_start
  end

  defp maybe_convert_start_time(scheduled_start) do
    scheduled_start
  end
end
