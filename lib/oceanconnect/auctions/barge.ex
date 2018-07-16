defmodule Oceanconnect.Auctions.Barge do
  use Ecto.Schema
  import Ecto.{Changeset, Query}
  alias Oceanconnect.Accounts.Company
  alias __MODULE__

  schema "barges" do
    belongs_to :supplier, Oceanconnect.Auctions.Supplier
    belongs_to :port, Oceanconnect.Auctions.Port
    field :name, :string
    field :approval_status, :string
    field :acceptability, :string
    field :imo_number, :string
    field :dwt, :string
    field :bvq_date, :naive_datetime
    field :bvq_validity, :string
    field :sire_inspection_date, :naive_datetime
    field :sire_inspection_validity, :string

    timestamps()
  end

  def changeset(%Barge{} = barge, attrs) do
    barge
    |> cast(attrs, [
      :name,
      :supplier_id,
      :port_id,
      :approval_status,
      :acceptability,
      :imo_number,
      :dwt,
      :bvq_date,
      :bvq_validity,
      :sire_inspection_date,
      :sire_inspection_validity
      ])
    |> foreign_key_constraint(:supplier_id)
    |> foreign_key_constraint(:port_id)
    |> validate_required([:name, :supplier_id, :port_id])
  end

end
