defmodule Oceanconnect.Auctions.AuctionSuppliers do
  use Ecto.Schema
  import Ecto.Changeset
  alias __MODULE__
  alias Oceanconnect.Accounts.Company
  alias Oceanconnect.Auctions.{Auction, AuctionSuppliers}
  alias Oceanconnect.Repo

  schema "auction_suppliers" do
    field(:participation, :string)
    field(:alias_name, :string)
    belongs_to(:auction, Oceanconnect.Auctions.Auction)
    belongs_to(:supplier, Oceanconnect.Accounts.Company)

    timestamps()
  end

  @doc false
  def changeset(%AuctionSuppliers{} = auction_suppliers, attrs) do
    auction_suppliers
    |> cast(attrs, [:participation, :alias_name, :auction_id, :supplier_id])
    |> validate_required([:auction_id, :supplier_id])
    |> foreign_key_constraint(:auction_id)
    |> foreign_key_constraint(:supplier_id)
    |> foreign_key_constraint(:barge_id)
  end

  def get_name_or_alias(buyer_id, %{buyer_id: buyer_id}) do
    Repo.get(Company, buyer_id).name
  end
  def get_name_or_alias(supplier_id, %Auction{anonymous_bidding: true, suppliers: suppliers}) do
    hd(Enum.filter(suppliers, &(&1.id == supplier_id))).alias_name
  end
  def get_name_or_alias(supplier_id, %{anonymous_bidding: true, auction_id: auction_id}) do
    Repo.get_by!(__MODULE__, %{auction_id: auction_id, supplier_id: supplier_id}).alias_name
  end
  def get_name_or_alias(supplier_id, %{suppliers: suppliers}) do
    hd(Enum.filter(suppliers, &(&1.id == supplier_id))).name
  end
  def get_name_or_alias(supplier_id, _) do
    Repo.get(Company, supplier_id).name
  end
end
