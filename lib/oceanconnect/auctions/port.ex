defmodule Oceanconnect.Auctions.Port do
  import Ecto.Query, warn: false
  use Ecto.Schema
  import Ecto.Changeset
  alias Oceanconnect.Auctions.Port

  @derive {Poison.Encoder, except: [:__meta__, :companies]}
  schema "ports" do
    field :name, :string
    field :country, :string
    field :gmt_offset, :integer
		field :is_active, :boolean, default: true
    many_to_many :companies, Oceanconnect.Accounts.Company, join_through: "company_ports", on_replace: :delete

    timestamps()
  end

  @doc false
  def changeset(%Port{} = port, attrs) do
    port
    |> cast(attrs, [:name, :country, :gmt_offset, :is_active])
    |> validate_required([:name, :country])
  end

  def suppliers_for_port_id(port_id) do
    from c in Oceanconnect.Accounts.Company,
      join: p in assoc(c, :ports),
      where: p.id == ^port_id and c.is_supplier == true,
      select: c
  end
  def suppliers_for_port_id(port_id, buyer_id) do
    from c in Oceanconnect.Accounts.Company,
      join: p in assoc(c, :ports),
      where: p.id == ^port_id and c.is_supplier == true and c.id != ^buyer_id,
      select: c
  end

	def select_active do
		from p in Port,
		  where: p.is_active == true
	end
end
