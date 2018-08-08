defmodule Oceanconnect.Auctions.Vessel do
  use Ecto.Schema
  import Ecto.{Changeset, Query}
  alias Oceanconnect.Auctions.{Vessel}
  alias Oceanconnect.Accounts.Company


  @derive {Poison.Encoder, except: [:__meta__, :company]}

  schema "vessels" do
    field :imo, :integer
    field :name, :string
		field :is_active, :boolean, default: true
    belongs_to :company, Company

    timestamps()
  end

  @doc false
  def changeset(%Vessel{} = vessel, attrs) do
    vessel
    |> cast(attrs, [:name, :imo, :company_id, :is_active])
    |> foreign_key_constraint(:company_id)
    |> validate_required([:name, :imo, :company_id])
  end

  def by_company(%Company{id: company_id}) do
    from v in Vessel,
      where: v.company_id == ^company_id
  end
  def by_company(company_id) when is_integer(company_id) do
    from v in Vessel,
      where: v.company_id == ^company_id
  end

	def select_active do
		from v in Vessel,
		  where: v.is_active == true
	end

	def alphabetical do
		from v in Vessel,
		  order_by: [asc: v.name]
	end
end
