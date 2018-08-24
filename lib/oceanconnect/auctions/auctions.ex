defmodule Oceanconnect.Auctions do
  import Ecto.Query, warn: false
  alias Oceanconnect.Repo
  alias Oceanconnect.Auctions.{
    Auction,
    AuctionBid,
    AuctionCache,
    AuctionEvent,
    AuctionEventStorage,
    AuctionStore,
    AuctionSuppliers,
    AuctionBarge,
    Port,
    Vessel,
    Fuel,
    Barge
  }
  alias Oceanconnect.Auctions.Command
  alias Oceanconnect.Accounts.Company
  alias Oceanconnect.Auctions.AuctionsSupervisor

  def place_bid(auction, bid_params, supplier_id, time_entered \\ DateTime.utc_now(), user \\ nil) do
    bid =
      bid_params
      |> maybe_add_amount
      |> maybe_add_min_amount
      |> Map.put("supplier_id", supplier_id)
      |> Map.put("time_entered", time_entered)
      |> AuctionBid.from_params_to_auction_bid(auction)

    bid
    |> Command.process_new_bid(user)
    |> AuctionStore.process_command()

    bid
  end

  defp maybe_add_amount(params = %{"amount" => _}), do: params
  defp maybe_add_amount(params), do: Map.put(params, "amount", nil)

  defp maybe_add_min_amount(params = %{"min_amount" => _}), do: params
  defp maybe_add_min_amount(params), do: Map.put(params, "min_amount", nil)

  def select_winning_bid(bid, comment, user \\ nil) do
    %{bid | comment: comment}
    |> Command.select_winning_bid(user)
    |> AuctionStore.process_command()
  end

  def is_participant?(auction = %Auction{}, company_id) do
    company_id in auction_participant_ids(auction)
  end

  def auction_participant_ids(auction = %Auction{}) do
    [auction.buyer_id | auction_supplier_ids(auction)]
  end

  def auction_supplier_ids(auction = %Auction{}) do
    auction_with_participants = with_participants(auction)
    Enum.map(auction_with_participants.suppliers, & &1.id)
  end

  def list_auctions do
    Repo.all(Auction)
    |> fully_loaded
  end

  def list_participating_auctions(company_id) do
    (buyer_auctions(company_id) ++ supplier_auctions(company_id))
    |> Enum.uniq_by(& &1.id)
  end

  def list_upcoming_auctions(time_frame) do
    Auction
    |> Auction.select_upcoming(time_frame)
    |> Repo.all()
  end

  def upcoming_notification_sent?(%Auction{id: auction_id}) do
    Enum.any?(AuctionEventStorage.events_by_auction(auction_id), fn(event) -> event.type == :auction_upcoming_notified end)
  end

  defp buyer_auctions(buyer_id) do
    query =
      from(
        a in Auction,
        where: a.buyer_id == ^buyer_id,
        order_by: a.scheduled_start
      )

    query
    |> Repo.all()
    |> fully_loaded
  end

  defp supplier_auctions(supplier_id) do
    query =
      from(
        as in AuctionSuppliers,
        join: a in Auction,
        on: a.id == as.auction_id,
        where: as.supplier_id == ^supplier_id,
        where: not is_nil(a.scheduled_start),
        select: a,
        order_by: a.scheduled_start
      )

    query
    |> Repo.all()
    |> Repo.preload([:port, [vessel: :company], :fuel, :buyer])
  end

  def get_auction(id) do
    Repo.get(Auction, id)
  end

  def get_auction!(id) do
    Repo.get!(Auction, id)
  end

  def get_auction_state!(auction = %Auction{}) do
    case AuctionStore.get_current_state(auction) do
      {:error, "Auction Store Not Started"} ->
        AuctionStore.AuctionState.from_auction(auction)

      state ->
        state
    end
  end

  def get_auction_supplier(auction_id, supplier_id) do
    Repo.get_by(AuctionSuppliers, %{auction_id: auction_id, supplier_id: supplier_id})
  end

  def start_auction(auction = %Auction{}, user \\ nil) do
    updated_auction = Map.put(auction, :auction_started, DateTime.utc_now())

    updated_auction
    |> Command.start_auction(user)
    |> AuctionStore.process_command()

    updated_auction
  end

  def end_auction(auction = %Auction{}) do
    updated_auction = Map.put(auction, :auction_ended, DateTime.utc_now())

    updated_auction
    |> Command.end_auction()
    |> AuctionStore.process_command()

    updated_auction
  end

  def expire_auction(auction = %Auction{}) do
    auction
    |> Command.end_auction_decision_period()
    |> AuctionStore.process_command()

    auction
  end

  def cancel_auction(auction = %Auction{}, user) do
    auction
    |> Command.cancel_auction(user)
    |> AuctionStore.process_command()

    auction
  end

  def notify_upcoming_auction(auction = %Auction{}) do
    auction
    |> Command.notify_upcoming_auction
    |> AuctionStore.process_command
    auction
  end

  def create_auction(attrs \\ %{}, user \\ nil)

  def create_auction(attrs = %{"scheduled_start" => start}, user) when start != "" do
    %Auction{}
    |> Auction.changeset_for_scheduled_auction(attrs)
    |> Repo.insert()
    |> handle_auction_creation(user)
  end

  def create_auction(attrs, user) do
    %Auction{}
    |> Auction.changeset(attrs)
    |> Repo.insert()
    |> handle_auction_creation(user)
  end

  defp handle_auction_creation({:ok, auction}, user) do
    user_on_record =
      case user do
        nil -> auction |> Repo.preload([:buyer]) |> Map.fetch!(:buyer)
        user -> user
      end

    auction
    |> fully_loaded
    |> create_supplier_aliases
    |> AuctionsSupervisor.start_child()

    event = AuctionEvent.auction_created(auction, user_on_record)
    AuctionEvent.emit(event, true)
    {:ok, auction}
  end

  defp handle_auction_creation({:error, changeset}, _user), do: {:error, changeset}

  def update_cache(auction = %Auction{}) do
    auction
    |> Command.update_cache()
    |> AuctionCache.process_command()
  end

  def create_supplier_aliases(auction = %{suppliers: suppliers}) do
    :random.seed()

    Enum.reduce(Enum.shuffle(suppliers), 1, fn supplier, acc ->
      AuctionSuppliers
      |> Repo.get_by(%{auction_id: auction.id, supplier_id: supplier.id})
      |> AuctionSuppliers.changeset(%{alias_name: "Supplier #{acc}"})
      |> Repo.update!()

      acc + 1
    end)

    auction
  end

  def update_auction(%Auction{} = auction, attrs, user) do
    auction
    |> Auction.changeset(attrs)
    |> Repo.update()
    |> auction_update_command(user)
  end

  def update_auction!(%Auction{} = auction, attrs, user) do
    auction
    |> Auction.changeset(attrs)
    |> Repo.update!()
    |> auction_update_command(user)
  end

  def update_auction_without_event_storage!(%Auction{} = auction, attrs) do
    cleaned_attrs = clean_timestamps(attrs)

    auction
    |> Auction.changeset(cleaned_attrs)
    |> Repo.update!()
  end

  defp clean_timestamps(attrs = %{auction_started: auction_started}) do
    Map.put(attrs, :auction_started, fix_time_weirdness(auction_started))
  end

  defp clean_timestamps(attrs = %{auction_ended: auction_ended}) do
    Map.put(attrs, :auction_ended, fix_time_weirdness(auction_ended))
  end

  defp clean_timestamps(attrs), do: attrs

  defp fix_time_weirdness(date_time = %DateTime{microsecond: microsecond}) do
    Map.put(date_time, :microsecond, {elem(microsecond, 0), 5})
  end

  def delete_auction(%Auction{} = auction) do
    Repo.delete(auction)
  end

  def change_auction(%Auction{} = auction) do
    Auction.changeset(auction, %{})
  end

  def with_participants(%Auction{} = auction) do
    auction
    |> Repo.preload([:buyer, :suppliers])
  end

  def suppliers_with_alias_names(%Auction{id: nil, suppliers: suppliers}), do: suppliers

  def suppliers_with_alias_names(auction = %Auction{suppliers: suppliers}) do
    Enum.map(suppliers, fn supplier ->
      alias_name = get_auction_supplier(auction.id, supplier.id).alias_name
      Map.put(supplier, :alias_name, alias_name)
    end)
  end

  def fully_loaded(auction = %Auction{}) do
    fully_loaded_auction =
      Repo.preload(auction, [:port, [vessel: :company], :fuel, :buyer, :suppliers])

    Map.put(fully_loaded_auction, :suppliers, suppliers_with_alias_names(fully_loaded_auction))
  end

  def fully_loaded(auctions) when is_list(auctions) do
    Enum.map(auctions, fn auction -> fully_loaded(auction) end)
  end

  def fully_loaded(company = %Company{}) do
    Repo.preload(company, [:users, :vessels, :ports])
  end

  def fully_loaded(port = %Port{}) do
    Repo.preload(port, [:companies])
  end

  def fully_loaded(vessel = %Vessel{}) do
    Repo.preload(vessel, [:company])
  end

  def fully_loaded(struct), do: struct

  def strip_non_loaded(struct = %{}) do
    Enum.reduce(maybe_convert_struct(struct), %{}, fn {k, v}, acc ->
      Map.put(acc, k, maybe_replace_non_loaded(v))
    end)
  end

  def strip_non_loaded(struct), do: struct

  defp auction_update_command({:ok, auction}, user) do
    auction
    |> fully_loaded
    |> Command.update_auction(user)
    |> AuctionStore.process_command()

    {:ok, auction}
  end

  defp auction_update_command({:error, changeset}, _user), do: {:error, changeset}

  defp auction_update_command(auction, user) do
    auction
    |> fully_loaded
    |> Command.update_auction(user)
    |> AuctionStore.process_command()

    auction
  end

  defp maybe_convert_struct(struct = %{__meta__: _meta}) do
    struct
    |> Map.from_struct()
    |> Map.drop([:__meta__, :inserted_at, :updated_at])
  end

  defp maybe_convert_struct(data), do: data

  defp maybe_replace_non_loaded(%Ecto.Association.NotLoaded{}), do: nil

  defp maybe_replace_non_loaded(value) when is_list(value) do
    Enum.map(value, fn list_item ->
      strip_non_loaded(list_item)
    end)
  end

  defp maybe_replace_non_loaded(value = %{__meta__: _meta}), do: strip_non_loaded(value)
  defp maybe_replace_non_loaded(value = %DateTime{}), do: value
  defp maybe_replace_non_loaded(value = %{}), do: strip_non_loaded(value)
  defp maybe_replace_non_loaded(value), do: value

  @doc """
  Returns the list of ports.

  ## Examples

      iex> list_ports()
      [%Port{}, ...]

  """
  def list_ports do
    Repo.all(Port)
  end

  def list_ports(params) do
    Port.alphabetical()
    |> Repo.paginate(params)
  end

  def list_active_ports do
    Port.select_active()
    |> Repo.all()
  end

  @doc """
  Gets a single port.

  Raises `Ecto.NoResultsError` if the Port does not exist.

  ## Examples

      iex> get_port!(123)
      %Port{}

      iex> get_port!(456)
      ** (Ecto.NoResultsError)

  """
  def get_port!(id), do: Repo.get!(Port, id)

  def get_active_port!(id) do
    Port.select_active()
    |> Repo.get!(id)
  end

  @doc """
  Creates a port.

  ## Examples

      iex> create_port(%{field: value})
      {:ok, %Port{}}

      iex> create_port(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_port(attrs \\ %{}) do
    %Port{}
    |> Port.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a port.

  ## Examples

      iex> update_port(port, %{field: new_value})
      {:ok, %Port{}}

      iex> update_port(port, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_port(%Port{} = port, attrs) do
    port
    |> Port.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Port.

  ## Examples

      iex> delete_port(port)
      {:ok, %Port{}}

      iex> delete_port(port)
      {:error, %Ecto.Changeset{}}

  """
  def delete_port(%Port{} = port) do
    Repo.delete(port)
  end

  def activate_port(port = %Port{}) do
    port
    |> Port.changeset(%{is_active: true})
    |> Repo.update()
  end

  def deactivate_port(port = %Port{}) do
    port
    |> Port.changeset(%{is_active: false})
    |> Repo.update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking port changes.

  ## Examples

      iex> change_port(port)
      %Ecto.Changeset{source: %Port{}}

  """
  def change_port(%Port{} = port) do
    Port.changeset(port, %{})
  end

  def ports_for_company(company = %Company{}) do
    company
    |> Repo.preload(ports: :companies)
    |> Map.get(:ports)
  end

  def supplier_list_for_auction(%Port{id: id}) do
    id
    |> Port.suppliers_for_port_id()
    |> Repo.all()
  end

  def supplier_list_for_auction(%Port{id: port_id}, buyer_id) do
    port_id
    |> Port.suppliers_for_port_id(buyer_id)
    |> Repo.all()
  end

  @doc """
  Returns list of vessels belonging to buyers company
  ## Examples
      iex> vessels_for_buyer(%Company{})
      [%Vessel{}, ...]

  """

  def vessels_for_buyer(%Company{id: id}) do
    Vessel.by_company(id)
    |> Vessel.select_active()
    |> Repo.all()
  end

  @doc """
  Returns the list of vessels.

  ## Examples

      iex> list_vessels()
      [%Vessel{}, ...]

  """
  def list_vessels do
    Repo.all(Vessel)
  end

  def list_vessels(params) do
    Vessel.alphabetical()
    |> Repo.paginate(params)
  end

  def list_active_vessels do
    Vessel.select_active()
    |> Repo.all()
  end

  @doc """
  Gets a single vessel.

  Raises `Ecto.NoResultsError` if the Vessel does not exist.

  ## Examples

      iex> get_vessel!(123)
      %Vessel{}

      iex> get_vessel!(456)
      ** (Ecto.NoResultsError)

  """
  def get_vessel!(id), do: Repo.get!(Vessel, id) |> Repo.preload(:company)

  def get_active_vessel!(id) do
    Vessel.select_active()
    |> Repo.get!(id)
  end

  @doc """
  Creates a vessel.

  ## Examples

      iex> create_vessel(%{field: value})
      {:ok, %Vessel{}}

      iex> create_vessel(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_vessel(attrs \\ %{}) do
    %Vessel{}
    |> Vessel.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a vessel.

  ## Examples

      iex> update_vessel(vessel, %{field: new_value})
      {:ok, %Vessel{}}

      iex> update_vessel(vessel, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_vessel(%Vessel{} = vessel, attrs) do
    vessel
    |> Vessel.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Vessel.

  ## Examples

      iex> delete_vessel(vessel)
      {:ok, %Vessel{}}

      iex> delete_vessel(vessel)
      {:error, %Ecto.Changeset{}}

  """
  def delete_vessel(%Vessel{} = vessel) do
    Repo.delete(vessel)
  end

  def activate_vessel(vessel = %Vessel{}) do
    vessel
    |> Vessel.changeset(%{is_active: true})
    |> Repo.update()
  end

  def deactivate_vessel(vessel = %Vessel{}) do
    vessel
    |> Vessel.changeset(%{is_active: false})
    |> Repo.update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking vessel changes.

  ## Examples

      iex> change_vessel(vessel)
      %Ecto.Changeset{source: %Vessel{}}

  """
  def change_vessel(%Vessel{} = vessel) do
    Vessel.changeset(vessel, %{})
  end

  @doc """
  Returns the list of fuels.

  ## Examples

      iex> list_fuels()
      [%Fuel{}, ...]

  """
  def list_fuels do
    Repo.all(Fuel)
  end

  def list_fuels(params) do
    Fuel.alphabetical()
    |> Repo.paginate(params)
  end

  def list_active_fuels do
    Fuel.select_active()
    |> Repo.all()
  end

  @doc """
  Gets a single fuel.

  Raises `Ecto.NoResultsError` if the Fuel does not exist.

  ## Examples

      iex> get_fuel!(123)
      %Fuel{}

      iex> get_fuel!(456)
      ** (Ecto.NoResultsError)

  """
  def get_fuel!(id), do: Repo.get!(Fuel, id)

  def get_active_fuel!(id) do
    Fuel.select_active()
    |> Repo.get!(id)
  end

  @doc """
  Creates a fuel.

  ## Examples

      iex> create_fuel(%{field: value})
      {:ok, %Fuel{}}

      iex> create_fuel(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_fuel(attrs \\ %{}) do
    %Fuel{}
    |> Fuel.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a fuel.

  ## Examples

      iex> update_fuel(fuel, %{field: new_value})
      {:ok, %Fuel{}}

      iex> update_fuel(fuel, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_fuel(%Fuel{} = fuel, attrs) do
    fuel
    |> Fuel.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Fuel.

  ## Examples

      iex> delete_fuel(fuel)
      {:ok, %Fuel{}}

      iex> delete_fuel(fuel)
      {:error, %Ecto.Changeset{}}

  """
  def delete_fuel(%Fuel{} = fuel) do
    Repo.delete(fuel)
  end

  def activate_fuel(fuel = %Fuel{}) do
    fuel
    |> Fuel.changeset(%{is_active: true})
    |> Repo.update()
  end

  def deactivate_fuel(fuel = %Fuel{}) do
    fuel
    |> Fuel.changeset(%{is_active: false})
    |> Repo.update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking fuel changes.

  ## Examples

      iex> change_fuel(fuel)
      %Ecto.Changeset{source: %Fuel{}}

  """
  def change_fuel(%Fuel{} = fuel) do
    Fuel.changeset(fuel, %{})
  end

  def list_barges, do: Repo.all(Barge)

  def list_barges(params) do
    Barge.alphabetical()
    |> Oceanconnect.Repo.paginate(params)
  end

  def list_active_barges do
    Barge.select_active()
    |> Repo.all()
  end

  def get_barge(id) do
    Repo.get(Barge, id)
  end

  def get_active_barge!(id) do
    Barge.select_active()
    |> Repo.get!(id)
  end

  def get_barge!(id) do
    Repo.get!(Barge, id)
  end

  def create_barge(attrs \\ %{}) do
    %Barge{}
    |> Barge.changeset(attrs)
    |> Repo.insert()
  end

  def update_barge(%Barge{} = barge, attrs) do
    barge
    |> Barge.changeset(attrs)
    |> Repo.update()
  end

  def delete_barge(%Barge{} = barge) do
    Repo.delete(barge)
  end

  def activate_barge(barge = %Barge{}) do
    barge
    |> Barge.changeset(%{is_active: true})
    |> Repo.update()
  end

  def deactivate_barge(barge = %Barge{}) do
    barge
    |> Barge.changeset(%{is_active: false})
    |> Repo.update()
  end

  def change_barge(%Barge{} = barge) do
    Barge.changeset(barge, %{})
  end

  def list_auction_barges(%Auction{id: auction_id}) do
    auction_id
    |> AuctionBarge.by_auction()
    |> Repo.all()
    |> Repo.preload(barge: [:port])
  end

  def submit_barge(
        %Auction{id: auction_id},
        barge = %Barge{id: barge_id},
        supplier_id,
        user \\ nil
      ) do
    {:ok, auction_barge} =
      %AuctionBarge{}
      |> AuctionBarge.changeset(%{
        auction_id: auction_id,
        barge_id: barge_id,
        supplier_id: supplier_id,
        approval_status: "PENDING"
      })
      |> Repo.insert()

    auction_barge
    |> Map.put(:barge, barge)
    |> Command.submit_barge(user)
    |> AuctionStore.process_command()
  end

  def unsubmit_barge(%Auction{id: auction_id}, %Barge{id: barge_id}, supplier_id, user \\ nil) do
    query =
      from(
        ab in AuctionBarge,
        where:
          ab.auction_id == ^auction_id and ab.supplier_id == ^supplier_id and
            ab.barge_id == ^barge_id
      )

    Repo.delete_all(query)

    %AuctionBarge{
      auction_id: auction_id,
      barge_id: barge_id,
      supplier_id: supplier_id
    }
    |> Command.unsubmit_barge(user)
    |> AuctionStore.process_command()
  end

  def approve_barge(%Auction{id: auction_id}, %Barge{id: barge_id}, supplier_id, user \\ nil) do
    query =
      from(
        ab in AuctionBarge,
        where:
          ab.auction_id == ^auction_id and ab.barge_id == ^barge_id and
            ab.supplier_id == ^supplier_id
      )

    Repo.update_all(query, set: [approval_status: "APPROVED"])

    auction_barges =
      query
      |> Repo.all()
      |> Repo.preload(barge: [:port])

    Enum.map(auction_barges, fn auction_barge ->
      auction_barge
      |> Command.approve_barge(user)
      |> AuctionStore.process_command()
    end)
  end

  def reject_barge(%Auction{id: auction_id}, %Barge{id: barge_id}, supplier_id, user \\ nil) do
    query =
      from(
        ab in AuctionBarge,
        where:
          ab.auction_id == ^auction_id and ab.barge_id == ^barge_id and
            ab.supplier_id == ^supplier_id
      )

    Repo.update_all(query, set: [approval_status: "REJECTED"])

    auction_barges =
      query
      |> Repo.all()
      |> Repo.preload(barge: [:port])

    Enum.map(auction_barges, fn auction_barge ->
      auction_barge
      |> Command.reject_barge(user)
      |> AuctionStore.process_command()
    end)
  end
end
