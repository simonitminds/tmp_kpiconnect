defmodule Oceanconnect.Auctions do
  import Ecto.Query, warn: false
  alias Oceanconnect.Repo

  alias Oceanconnect.Auctions.{Auction, AuctionStore, Port, Vessel, Fuel}
  alias Oceanconnect.Auctions.AuctionStore.{AuctionCommand, AuctionState}
  alias Oceanconnect.Accounts.{User}
  alias Oceanconnect.Auctions.AuctionsSupervisor

  def list_auctions do
    Repo.all(Auction)
    |> fully_loaded
  end

  def get_auction!(id) do
     Repo.get!(Auction, id)
   end

  def auction_status(auction = %Auction{}) do
    case AuctionStore.get_current_state(auction) do
      {:error, "Not Started"} -> :pending
      %AuctionState{status: status} -> status
    end
  end

  def start_auction(auction = %Auction{}) do
    auction
    |> AuctionCommand.start_auction()
    |> AuctionStore.process_command(auction.id)

    auction
    |> Repo.preload([:suppliers, :buyer])
    |> Oceanconnect.Auctions.notify_participants("auctions:lobby", AuctionStore.get_current_state(auction))
  end

  def notify_participants(%{buyer: buyer, suppliers: suppliers}, channel, payload) do
    buyer_id = buyer.id
    supplier_ids = Enum.map(suppliers, fn(s) -> s.id end)
    Enum.map([buyer_id | supplier_ids], fn(id) ->
      OceanconnectWeb.Endpoint.broadcast("user_socket:#{id}:#{channel}", "auctions_update", payload)
    end)
  end

  def create_auction(attrs \\ %{}) do
    auction = %Auction{}
    |> Auction.changeset(attrs)
    |> Repo.insert()

    case auction do
      {:ok, auction} ->
        AuctionsSupervisor.start_child(auction.id)
        {:ok, auction}
      {:error, changeset} ->
        {:error, changeset}
    end
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

  def fully_loaded(data) do
    data
    |> Repo.preload([:port, [vessel: :company], :fuel, [buyer: :company], [suppliers: :company]])
  end

  def add_supplier_to_auction(%Auction{} = auction, %Oceanconnect.Accounts.User{} = supplier) do
    auction_with_suppliers = auction
    |> Repo.preload(:suppliers)

    auction_with_suppliers
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:suppliers, [supplier | auction_with_suppliers.suppliers])
    |> Repo.update!
  end

  def set_suppliers_for_auction(%Auction{} = auction, suppliers) when is_list(suppliers) do
    auction
    |> Repo.preload(:suppliers)
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:suppliers, suppliers)
    |> Repo.update!
  end

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


  def companies_by_port(port_id) do
    query = from company_port in "company_ports",
      join: company in Oceanconnect.Accounts.Company, on: company.id == company_port.company_id,
      where: company_port.port_id == ^port_id,
      select: company
    query |> Repo.all
  end


  @doc """
  Returns list of vessels belonging to buyers company
  ## Examples
      iex> vessels_for_buyer(%User{})
      [%Vessel{}, ...]

  """

  def vessels_for_buyer(%User{company_id: company_id}) do
    Vessel.by_company(company_id)
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
    |> Repo.preload(:company)
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
