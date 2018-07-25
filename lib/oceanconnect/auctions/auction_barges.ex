defmodule Oceanconnect.Auctions.AuctionBarges do
  use Ecto.Schema
  import Ecto.Changeset
  alias __MODULE__
  alias Oceanconnect.Auctions.AuctionSuppliers

  schema "auctions_barges" do
    field :approval_status, :string
    belongs_to :barge, Oceanconnect.Auctions.Barge
    belongs_to :auction, Oceanconnect.Auctions.Auction
    belongs_to :supplier, Oceanconnect.Accounts.Company

    timestamps()
  end

  @doc false
  def changeset(%AuctionBarges{} = auction_barges, attrs) do
    auction_barges
    |> cast(attrs, [:approval_status, :barge_id, :auction_id, :supplier_id])
    |> validate_required([:barge_id, :auction_id, :supplier_id])
    |> foreign_key_constraint(:auction_id)
    |> foreign_key_constraint(:supplier_id)
    |> foreign_key_constraint(:barge_id)
  end
end
