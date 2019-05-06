defmodule Oceanconnect.Auctions.AuctionBarge do
  use Ecto.Schema
  import Ecto.{Changeset, Query}
  alias __MODULE__

  @derive {Poison.Encoder, except: [:__meta__, :auction, :supplier]}

  schema "auctions_barges" do
    belongs_to(:auction, Oceanconnect.Auctions.Auction)
    belongs_to(:barge, Oceanconnect.Auctions.Barge)
    belongs_to(:supplier, Oceanconnect.Accounts.Company)
    field(:approval_status, :string)

    timestamps()
  end

  def changeset(%AuctionBarge{} = auction_barge, attrs) do
    auction_barge
    |> cast(attrs, [:approval_status, :barge_id, :auction_id, :supplier_id])
    |> validate_required([:barge_id, :auction_id, :supplier_id])
    |> foreign_key_constraint(:auction_id)
    |> foreign_key_constraint(:supplier_id)
    |> foreign_key_constraint(:barge_id)
  end

  def by_auction(auction_id) do
    from(
      ab in AuctionBarge,
      where: ab.auction_id == ^auction_id
    )
  end

  def by_approval_status(status, query \\ AuctionBarge) do
    from(
      q in query,
      where: q.approval_status == ^String.upcase(status)
    )
  end

  def by_supplier(supplier_id, query \\ AuctionBarge) do
    from(
      q in query,
      where: q.supplier_id == ^supplier_id
    )
  end
end
