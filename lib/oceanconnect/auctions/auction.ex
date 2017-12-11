defmodule Oceanconnect.Auctions.Auction do
  use Ecto.Schema
  import Ecto.Changeset
  alias Oceanconnect.Auctions.Auction


  schema "auctions" do
    field :port, :string
    field :vessel, :string

    timestamps()
  end

  @doc false
  def changeset(%Auction{} = auction, attrs) do
    auction
    |> cast(attrs, [:vessel, :port])
    |> validate_required([:vessel, :port])
  end
end
