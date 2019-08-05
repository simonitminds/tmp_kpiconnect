defmodule Oceanconnect.Accounts.Observer do
  use Ecto.Schema
  import Ecto.Changeset

  alias Oceanconnect.Auctions.{Auction, TermAuction}
  alias Oceanconnect.Accounts.User

  @derive {Poison.Encoder, except: [:__meta__, :auction, :term_auction]}

  schema "observers" do
    belongs_to(:auction, Auction)
    belongs_to(:term_auction, TermAuction)
    belongs_to(:user, User)

    timestamps()
  end

  def changeset(%__MODULE__{} = observer, attrs) do
    observer
    |> cast(attrs, [:auction_id, :term_auction_id, :user_id])
    |> validate_required([:supplier_id])
    |> foreign_key_constraint(:auction_id)
    |> foreign_key_constraint(:term_auction_id)
    |> foreign_key_constraint(:user_id)
  end
end
