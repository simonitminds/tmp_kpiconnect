defmodule Oceanconnect.Auctions.Vessel do
  use Ecto.Schema
  import Ecto.Changeset
  alias Oceanconnect.Auctions.{Vessel}
  alias Oceanconnect.Accounts.Company


  @derive {Poison.Encoder, except: [:__meta__]}

  schema "vessels" do
    field :imo, :integer
    field :name, :string
    belongs_to :company, Company

    timestamps()
  end

  @doc false
  def changeset(%Vessel{} = vessel, attrs) do
    vessel
    |> cast(attrs, [:name, :imo, :company_id])
    |> foreign_key_constraint(:company_id)
    |> validate_required([:name, :imo, :company_id])
  end
end
