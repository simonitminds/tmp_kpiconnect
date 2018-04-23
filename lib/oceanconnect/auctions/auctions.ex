defmodule Oceanconnect.Auctions do
  import Ecto.Query, warn: false
  alias Oceanconnect.Repo
  alias Oceanconnect.Auctions.{Auction, AuctionBidList, AuctionEvent, AuctionStore, AuctionSuppliers, Port, Vessel, Fuel}
  alias Oceanconnect.Auctions.Command
  alias Oceanconnect.Accounts.Company
  alias Oceanconnect.Auctions.AuctionsSupervisor

  def place_bid(auction, bid_params = %{"amount" => _amount}, supplier_id, time_entered \\ DateTime.utc_now()) do
    bid = bid_params
    |> Map.put("supplier_id", supplier_id)
    |> Map.put("time_entered", time_entered)
    |> AuctionBidList.AuctionBid.from_params_to_auction_bid(auction)

    bid
    |> Command.process_new_bid
    |> AuctionStore.process_command

    bid
  end

  def select_winning_bid(bid, comment) do
    bid
    |> Map.put(:comment, comment)
    |> Command.select_winning_bid
    |> AuctionStore.process_command
  end

  def is_participant?(auction = %Auction{}, company_id) do
    company_id in auction_participant_ids(auction)
  end

  def auction_participant_ids(auction = %Auction{}) do
    [auction.buyer_id | auction_supplier_ids(auction)]
  end

  def auction_supplier_ids(auction = %Auction{}) do
    auction_with_participants = with_participants(auction)
    Enum.map(auction_with_participants.suppliers, &(&1.id))
  end

  def list_auctions do
    Repo.all(Auction)
    |> fully_loaded
  end

  def list_participating_auctions(company_id) do
    buyer_auctions(company_id) ++ supplier_auctions(company_id)
  end

  defp buyer_auctions(buyer_id) do
    query = from a in Auction,
      where: a.buyer_id == ^buyer_id
    query
    |> Repo.all
    |> fully_loaded
  end

  defp supplier_auctions(supplier_id) do
    query = from as in AuctionSuppliers,
      join: a in Auction, on: a.id == as.auction_id,
      where: as.supplier_id == ^supplier_id,
      select: a
    query
    |> Repo.all
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
        AuctionStore.AuctionState.from_auction(auction.id)
        |> Map.put(:status, :pending)
      state -> state
    end
  end

  def get_auction_supplier(auction_id, supplier_id) do
    Repo.get_by(AuctionSuppliers, %{auction_id: auction_id, supplier_id: supplier_id})
  end

  def start_auction(auction = %Auction{}) do
    auction
    |> Command.start_auction
    |> AuctionStore.process_command

    update_auction!(auction, %{auction_start: DateTime.utc_now()})
  end

  def end_auction(auction = %Auction{}) do
    auction
    |> Command.end_auction
    |> AuctionStore.process_command
  end

  def create_auction(attrs \\ %{}) do
    auction = %Auction{}
    |> Auction.changeset(attrs)
    |> Repo.insert()

    case auction do
      {:ok, auction} ->
        auction
        |> fully_loaded
        |> create_supplier_aliases
        |> AuctionsSupervisor.start_child
        AuctionEvent.emit(%AuctionEvent{type: :auction_created, auction_id: auction.id, data: auction, time_entered: DateTime.utc_now()}, true)
        {:ok, auction}
      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def create_supplier_aliases(auction = %{suppliers: suppliers}) do
    :random.seed()
    Enum.reduce(Enum.shuffle(suppliers), 1, fn(supplier, acc) ->
      AuctionSuppliers
      |> Repo.get_by(%{auction_id: auction.id, supplier_id: supplier.id})
      |> AuctionSuppliers.changeset(%{alias_name: "Supplier #{acc}"})
      |> Repo.update!
      acc + 1
    end)
    auction
  end

  def update_auction(%Auction{} = auction, attrs) do
    auction
    |> Auction.changeset(attrs)
    |> Repo.update()
    |> emit_auction_update
  end

  def update_auction!(%Auction{} = auction, attrs) do
    auction
    |> Auction.changeset(attrs)
    |> Repo.update!()
    |> emit_auction_update
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

  def suppliers_with_alias_names(auction = %Auction{suppliers: suppliers}) do
    Enum.map(suppliers, fn(supplier) ->
      alias_name = get_auction_supplier(auction.id, supplier.id).alias_name
      Map.put(supplier, :alias_name, alias_name)
    end)
  end

  def fully_loaded(auction = %Auction{}) do
    fully_loaded_auction = Repo.preload(auction, [:port, [vessel: :company], :fuel, :buyer, :suppliers])
    Map.put(fully_loaded_auction, :suppliers, suppliers_with_alias_names(fully_loaded_auction))
  end
  # is this needed?
  def fully_loaded(auctions) when is_list(auctions) do
    Enum.map(auctions, fn(auction) ->
      fully_loaded_auction = Repo.preload(auction, [:port, [vessel: :company], :fuel, :buyer, :suppliers])
      Map.put(fully_loaded_auction, :suppliers, suppliers_with_alias_names(fully_loaded_auction))
    end)
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
    Enum.reduce(maybe_convert_struct(struct), %{}, fn({k, v}, acc) ->
      Map.put(acc, k, maybe_replace_non_loaded(v))
    end)
  end
  def strip_non_loaded(struct), do: struct

  defp emit_auction_update({:ok, auction}) do
    auction
    |> fully_loaded
    |> Command.update_auction
    |> AuctionStore.process_command
    {:ok, auction}
  end
  defp emit_auction_update({:error, changeset}), do: {:error, changeset}
  defp emit_auction_update(auction) do
    auction
    |> fully_loaded
    |> Command.update_auction
    |> AuctionStore.process_command
    auction
  end

  defp maybe_convert_struct(struct = %{__meta__: _meta}) do
    struct
    |> Map.from_struct
    |> Map.drop([:__meta__, :inserted_at, :updated_at])
  end
  defp maybe_convert_struct(data), do: data

  defp maybe_replace_non_loaded(%Ecto.Association.NotLoaded{}), do: nil
  defp maybe_replace_non_loaded(value) when is_list(value) do
    Enum.map(value, fn(list_item) ->
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
    |> Repo.preload([ports: :companies])
    |> Map.get(:ports)
  end

  def supplier_list_for_auction(%Port{id: id}) do
    id
    |> Port.suppliers_for_port_id
    |> Repo.all
  end
  def supplier_list_for_auction(%Port{id: port_id}, buyer_id) do
    port_id
    |> Port.suppliers_for_port_id(buyer_id)
    |> Repo.all
  end

  @doc """
  Returns list of vessels belonging to buyers company
  ## Examples
      iex> vessels_for_buyer(%Company{})
      [%Vessel{}, ...]

  """

  def vessels_for_buyer(%Company{id: id}) do
    Vessel.by_company(id)
    |> Repo.all
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

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking fuel changes.

  ## Examples

      iex> change_fuel(fuel)
      %Ecto.Changeset{source: %Fuel{}}

  """
  def change_fuel(%Fuel{} = fuel) do
    Fuel.changeset(fuel, %{})
  end
end
