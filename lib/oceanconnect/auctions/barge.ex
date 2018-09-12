defmodule Oceanconnect.Auctions.Barge do
  use Ecto.Schema
  import Ecto.{Changeset, Query}
  alias __MODULE__

  @derive {Poison.Encoder, except: [:__meta__, :companies]}

  schema "barges" do
    belongs_to(:port, Oceanconnect.Auctions.Port)
    field(:name, :string)
    field(:imo_number, :string)
    field(:dwt, :string)
    field(:sire_inspection_date, :naive_datetime)
    field(:sire_inspection_validity, :boolean)
    field(:is_active, :boolean, default: true)

    many_to_many(
      :companies,
      Oceanconnect.Accounts.Company,
      join_through: "company_barges",
      on_replace: :delete,
      on_delete: :delete_all
    )

    timestamps()
  end

  def changeset(%Barge{} = barge, attrs) do
    barge
    |> cast(attrs, [
      :name,
      :port_id,
      :imo_number,
      :dwt,
      :sire_inspection_date,
      :sire_inspection_validity,
      :is_active
    ])
    |> foreign_key_constraint(:port_id)
    |> validate_required([:name, :port_id])
  end

  def by_company(company_id) do
    from(
      b in Barge,
      distinct: b.id,
      join: cb in "company_barges",
      where: cb.barge_id == b.id and cb.company_id == ^company_id
    )
  end

  def alphabetical(query \\ Barge) do
    from(
      q in query,
      order_by: [asc: q.name]
    )
  end

  def select_active(query \\ Barge) do
    from(
      q in query,
      where: q.is_active == true
    )
  end
end