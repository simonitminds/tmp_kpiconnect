defmodule Oceanconnect.Auctions do
  import Ecto.Query, warn: false
  alias Oceanconnect.Repo
  alias Oceanconnect.Auctions.{Auction, AuctionBidList, AuctionNotifier, AuctionStore, AuctionSuppliers, Port, Vessel, Fuel}
  alias Oceanconnect.Auctions.Command
  alias Oceanconnect.Accounts.Company
  alias Oceanconnect.Auctions.AuctionsSupervisor



  def place_bid(auction, bid_params = %{"amount" => _amount}, supplier_id) do
    bid = bid_params
    |> Map.put("supplier_id", supplier_id)
    |> AuctionBidList.AuctionBid.from_params_to_auction_bid(auction)

    bid
    |> Command.process_new_bid
    |> AuctionStore.process_command

    bid
    |> Command.enter_bid
    |> AuctionBidList.process_command

    AuctionNotifier.notify_updated_bid(auction, bid, supplier_id)

    bid
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
    Repo.all(query)
    |> Repo.preload([:port, [vessel: :company], :fuel, :buyer])
  end

  def get_auction(id) do
    Repo.get(Auction, id)
  end

  def get_auction!(id) do
    Repo.get!(Auction, id)
  end

  def get_auction_state(auction = %Auction{id: id}) do
    case AuctionStore.get_current_state(auction) do
      {:error, "Auction Store Not Started"} -> %{auction_id: id, status: :pending}
      state -> state
    end
  end

  def build_auction_state_payload(auction_state, user_id) when is_integer(user_id) do
    auction_state
    |> add_bid_list(user_id)
    |> structure_payload
  end
  def build_auction_state_payload(auction_state, user_id) do
    auction_state
    |> add_bid_list(String.to_integer(user_id))
    |> structure_payload
  end

  defp add_bid_list(auction_state = %{auction_id: auction_id, buyer_id: buyer_id, status: status}, buyer_id)
    when status != :pending do
    current_bid_list = AuctionBidList.get_bid_list(auction_id)
    auction_state
    |> Map.put(:bid_list, current_bid_list)
    |> add_supplier_names()
  end
  defp add_bid_list(auction_state = %{auction_id: auction_id, status: status}, supplier_id) when status != :pending do
    supplier_bid_list = auction_id
    |> AuctionBidList.get_bid_list
    |> supplier_bid_list(supplier_id)

    auction_state
    |> Map.put(:bid_list, supplier_bid_list)
    |> convert_winning_bidss_for_supplier(supplier_id)
  end
  defp add_bid_list(auction_state, _user_id) do
    auction_state
    |> Map.put(:bid_list, [])
  end

  def supplier_bid_list(bid_list, supplier_id) do
    Enum.filter(bid_list, fn(bid) -> bid.supplier_id == supplier_id end)
  end

  defp convert_winning_bidss_for_supplier(auction_state = %{winning_bids: []}, _supplier_id), do: auction_state
  defp convert_winning_bidss_for_supplier(auction_state, supplier_id) do
    winning_bids_suppliers_ids = Enum.map(auction_state.winning_bids, fn(bid) -> bid.supplier_id end)
    order = Enum.find_index(winning_bids_suppliers_ids, fn(id) -> id == supplier_id end)

    auction_state
    |> Map.put(:winning_bids, [hd(auction_state.winning_bids)])
    |> Map.put(:winning_bids_position, order)
  end

  defp add_supplier_names(payload) do
    bid_list = convert_to_supplier_names(payload.bid_list, payload.auction_id)
    winning_bids = convert_to_supplier_names(payload.winning_bids, payload.auction_id)
    payload
    |> Map.put(:bid_list, bid_list)
    |> Map.put(:winning_bids, winning_bids)
  end

  def convert_to_supplier_names(bid_list, auction_id) do
    auction = Repo.get(Auction, auction_id)
    Enum.map(bid_list, fn(bid) ->
      supplier_name = get_name_or_alias(bid.supplier_id, auction_id, auction.anonymous_bidding)
      bid
      |> Map.drop([:__struct__, :supplier_id])
      |> Map.put(:supplier, supplier_name)
    end)
  end

  defp get_name_or_alias(supplier_id, auction_id, _anonymous_biding = true) do
    get_auction_supplier(auction_id, supplier_id).alias_name
  end
  defp get_name_or_alias(supplier_id, _auction_id,  _anonymous_biding) do
    Oceanconnect.Accounts.get_company!(supplier_id).name
  end

  def get_auction_supplier(auction_id, supplier_id) do
    Repo.get_by(AuctionSuppliers, %{auction_id: auction_id, supplier_id: supplier_id})
  end

  defp structure_payload(auction_state = %{bid_list: bid_list}) do
    state = Map.drop(auction_state, [:__struct__, :auction_id, :buyer_id, :supplier_ids])
    %{id: auction_state.auction_id, state: Map.delete(state, :bid_list), bid_list: bid_list}
  end
  defp structure_payload(auction_state) do
    state = Map.drop(auction_state, [:__struct__, :auction_id, :buyer_id, :supplier_ids])
    %{id: auction_state.auction_id, state: state}
  end

  def start_auction(auction = %Auction{}) do
    auction
    |> Command.start_auction
    |> AuctionStore.process_command

    update_auction(auction, %{auction_start: DateTime.utc_now()})
  end

  def create_auction(attrs \\ %{}) do
    auction = %Auction{}
    |> Auction.changeset(attrs)
    |> Repo.insert()

    case auction do
      {:ok, auction} ->
        auction_with_participants = auction
        |> with_participants
        |> create_supplier_aliases

        AuctionsSupervisor.start_child(auction_with_participants)
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

  def fully_loaded(auction = %Auction{}) do
    Repo.preload(auction, [:port, [vessel: :company], :fuel, :buyer, :suppliers])
  end
  def fully_loaded(auctions = []) do
    Repo.preload(auctions, [:port, [vessel: :company], :fuel, :buyer, :suppliers])
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
