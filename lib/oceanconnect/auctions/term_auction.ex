defmodule Oceanconnect.Auctions.TermAuction do
  import Ecto.Query
  use Ecto.Schema
  import Ecto.Changeset
  alias Oceanconnect.Auctions.{TermAuction, Fuel, Port, Vessel, AuctionVessel}

  @derive {Poison.Encoder, except: [:__meta__, :auction_suppliers]}
  schema "term_auctions" do
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
    field(:anonymous_bidding, :boolean)
    field(:is_traded_bid_allowed, :boolean)
    field(:additional_information, :string)

    belongs_to(:port, Port)
    belongs_to(:buyer, Oceanconnect.Accounts.Company)
    belongs_to(:fuel, Fuel)
    field(:fuel_quantity, :integer)

    many_to_many(
      :vessels,
      Vessel,
      join_through: AuctionVessel,
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
    :port_id
  ]

  @optional_fields [
    :additional_information,
    :anonymous_bidding,
    :auction_ended,
    :auction_closed_time,
    :auction_started,
    :buyer_id,
    :duration,
    :end_date,
    :fuel_id,
    :is_traded_bid_allowed,
    :po,
    :port_agent,
    :scheduled_start,
    :start_date,
    :vessels
  ]

  @doc false
  def changeset(%TermAuction{} = auction, attrs) do
    auction
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> cast_assoc(:buyer)
    |> cast_assoc(:port)
    |> cast_assoc(:vessels)
    |> cast_assoc(:fuel)
    |> validate_scheduled_start(attrs)
    |> maybe_add_suppliers(attrs)
  end

  def changeset_for_scheduled_auction(%TermAuction{} = auction, attrs) do
    auction
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields ++ [:scheduled_start])
    |> cast_assoc(:buyer)
    |> cast_assoc(:port)
    |> cast_assoc(:vessels)
    |> cast_assoc(:fuel)
    |> validate_scheduled_start(attrs)
    |> maybe_add_suppliers(attrs)
  end

  def maybe_add_suppliers(changeset, %{"suppliers" => suppliers}) do
    put_assoc(changeset, :suppliers, suppliers)
  end

  def maybe_add_suppliers(changeset, %{suppliers: suppliers}) do
    put_assoc(changeset, :suppliers, suppliers)
  end

  def maybe_add_suppliers(changeset, _attrs), do: changeset

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
