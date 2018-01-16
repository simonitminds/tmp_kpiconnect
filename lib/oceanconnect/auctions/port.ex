defmodule Oceanconnect.Auctions.Port do
  use Ecto.Schema
  import Ecto.Changeset
  alias Oceanconnect.Auctions.Port

  @derive {Poison.Encoder, except: [:__meta__, :companies]}
  schema "ports" do
    field :name, :string
    field :country, :string
    field :gmt_offset, :integer
    many_to_many :companies, Oceanconnect.Accounts.Company, join_through: "company_ports", on_replace: :delete

    timestamps()
  end

  @doc false
  def changeset(%Port{} = port, attrs) do
    port
    |> cast(attrs, [:name, :country, :gmt_offset])
    |> validate_required([:name, :country])
  end
end
