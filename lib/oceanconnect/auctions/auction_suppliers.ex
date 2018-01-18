defmodule Oceanconnect.Auctions.AuctionSuppliers do
  use Ecto.Schema
  import Ecto.Changeset
  alias Oceanconnect.Auctions.AuctionSuppliers


  schema "auction_suppliers" do
    field :participation, :string
    belongs_to :auction, Oceanconnect.Auctions.Auction
    belongs_to :supplier, Oceanconnect.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(%AuctionSuppliers{} = auction_suppliers, attrs) do
    auction_suppliers
    |> cast(attrs, [:participation, :auction_id, :supplier_id])
    |> validate_required([:auction_id, :supplier_id])
    |> foreign_key_constraint(:auction_id)
    |> foreign_key_constraint(:supplier_id)
  end
end
