defmodule Oceanconnect.Auctions.Port do
  import Ecto.Query, warn: false
  use Ecto.Schema
  import Ecto.Changeset
  alias Oceanconnect.Auctions.Port

  @derive {Poison.Encoder, except: [:__meta__, :companies]}
  schema "ports" do
    field(:name, :string)
    field(:country, :string)
    field(:gmt_offset, :integer)
    field(:is_active, :boolean, default: true)

    many_to_many(
      :companies,
      Oceanconnect.Accounts.Company,
      join_through: "company_ports",
      on_replace: :delete,
      on_delete: :delete_all
    )

    timestamps()
  end

  @doc false
  def changeset(%Port{} = port, attrs) do
    port
    |> cast(attrs, [:name, :country, :gmt_offset, :is_active])
    |> validate_required([:name, :country])
  end

  def admin_changeset(%Port{} = port, attrs = %{"companies" => companies}) do
    port
    |> cast(attrs, [:name, :country, :gmt_offset, :is_active])
    |> validate_required([:name, :country])
    |> put_assoc(:companies, companies)
  end

  def admin_changeset(%Port{} = port, attrs) do
    changeset(port, attrs)
  end

  def suppliers_for_port_id(port_id) do
    from(
      c in Oceanconnect.Accounts.Company,
      join: p in assoc(c, :ports),
      where: p.id == ^port_id and c.is_supplier == true,
      select: c
    )
  end

  def suppliers_for_port_id(port_id, buyer_id) do
    from(
      c in Oceanconnect.Accounts.Company,
      join: p in assoc(c, :ports),
      where: p.id == ^port_id and c.is_supplier == true and c.id != ^buyer_id,
      select: c
    )
  end

  def alphabetical(query \\ Port) do
    from(
      q in query,
      order_by: [asc: q.name]
    )
  end

  def select_active(query \\ Port) do
    from(
      q in query,
      where: q.is_active == true
    )
  end
end
