defmodule Oceanconnect.Auctions.AuctionSuppliers do
  use Ecto.Schema
  import Ecto.Changeset

  import Oceanconnect.Auctions.Guards

  alias __MODULE__
  alias Oceanconnect.Accounts.Company
  alias Oceanconnect.Auctions.{Auction, AuctionSuppliers, TermAuction}
  alias Oceanconnect.Repo

  schema "auction_suppliers" do
    field(:participation, :string)
    field(:alias_name, :string)
    belongs_to(:supplier, Company)

    # Auctions and TermAuctions both reference this table. Each knows which
    # column to use as the foreign_key_constraint.
    belongs_to(:auction, Auction)
    belongs_to(:term_auction, TermAuction)

    timestamps()
  end

  @doc false
  def changeset(%AuctionSuppliers{} = auction_suppliers, attrs) do
    auction_suppliers
    |> cast(attrs, [:participation, :alias_name, :auction_id, :term_auction_id, :supplier_id])
    |> validate_required([:supplier_id])
    |> validate_belongs_to_an_auction()
    |> foreign_key_constraint(:auction_id)
    |> foreign_key_constraint(:term_auction_id)
    |> foreign_key_constraint(:supplier_id)
    |> foreign_key_constraint(:barge_id)
  end

  def get_name_or_alias(buyer_id, %{buyer_id: buyer_id}) do
    Repo.get(Company, buyer_id).name
  end

  def get_name_or_alias(supplier_id, %struct{anonymous_bidding: true, suppliers: suppliers})
      when is_auction(struct) do
    hd(Enum.filter(suppliers, &(&1.id == supplier_id))).alias_name
  end

  def get_name_or_alias(supplier_id, %{anonymous_bidding: true, auction_id: auction_id}) do
    Repo.get_by!(__MODULE__, %{auction_id: auction_id, supplier_id: supplier_id}).alias_name
  end

  def get_name_or_alias(supplier_id, %{suppliers: []}), do: ""

  def get_name_or_alias(supplier_id, %{suppliers: suppliers}) when is_list(suppliers) do
    hd(Enum.filter(suppliers, &(&1.id == supplier_id))).name
  end

  def get_name_or_alias(supplier_id, _) do
    Repo.get(Company, supplier_id).name
  end

  defp validate_belongs_to_an_auction(changeset) do
    case Ecto.Changeset.get_field(changeset, :auction_id) ||
           Ecto.Changeset.get_field(changeset, :term_auction_id) do
      nil ->
        changeset
        |> Ecto.Changeset.add_error(
          :auction_id,
          "at least one of auction_id or term_auction_id must be given"
        )
        |> Ecto.Changeset.add_error(
          :term_auction_id,
          "at least one of auction_id or term_auction_id must be given"
        )

      _ ->
        changeset
    end
  end
end
