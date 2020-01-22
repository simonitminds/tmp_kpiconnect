defmodule Oceanconnect.Auctions.AuctionSupplierCOQ do
  use Ecto.Schema
  # use Arc.Ecto.Schema
  import Ecto.Changeset
  alias __MODULE__

  schema "auction_supplier_coqs" do
    field(:file_extension, :string)
    # Auctions and TermAuctions both reference this table. Each knows which
    # column to use as the foreign_key_constraint.
    belongs_to(:auction, Oceanconnect.Auctions.Auction)
    belongs_to(:term_auction, Oceanconnect.Auctions.TermAuction)
    belongs_to(:supplier, Oceanconnect.Accounts.Company)
    belongs_to(:fuel, Oceanconnect.Auctions.Fuel)

    timestamps()
  end

  def changeset(%AuctionSupplierCOQ{} = auction_supplier_coq, attrs) do
    auction_supplier_coq
    |> cast(attrs, [:auction_id, :term_auction_id, :supplier_id, :fuel_id, :file_extension])
    |> validate_required([:supplier_id, :fuel_id, :file_extension])
    |> validate_belongs_to_an_auction()
    |> foreign_key_constraint(:auction_id)
    |> foreign_key_constraint(:term_auction_id)
    |> foreign_key_constraint(:supplier_id)
    |> foreign_key_constraint(:fuel_id)
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
