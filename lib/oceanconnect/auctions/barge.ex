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

  def admin_changeset(%Barge{} = barge, attrs = %{"companies" => companies}) do
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
    |> put_assoc(:companies, companies)
    |> foreign_key_constraint(:port_id)
    |> validate_required([:name, :port_id])
  end

  def admin_changeset(%Barge{} = barge, attrs), do: changeset(barge, attrs)

  def by_company(company_id) do
    "company_barges"
    |> join(:inner, [cb], barge in Barge, on: barge.id == cb.barge_id)
    |> where([cb, barge], cb.company_id == ^company_id and barge.is_active == true)
    |> select([_cb, barge], barge)
    |> order_by([_cb, barge], barge.name)
  end

  def alphabetical(query \\ Barge), do: order_by(query, :name)

  def select_active(query \\ Barge), do: query |> alphabetical() |> where(is_active: true)
end
