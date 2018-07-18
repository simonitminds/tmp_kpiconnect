defmodule Oceanconnect.Auctions.Barge do
  use Ecto.Schema
  import Ecto.{Changeset, Query}
  alias Oceanconnect.Accounts.Company
  alias __MODULE__

  schema "barges" do
    belongs_to :port, Oceanconnect.Auctions.Port
    field :name, :string
    field :imo_number, :string
    field :dwt, :string
    field :sire_inspection_date, :naive_datetime
    field :sire_inspection_validity, :boolean
    many_to_many :companies, Oceanconnect.Accounts.Company, join_through: "company_barges", on_replace: :delete

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
      :sire_inspection_validity
      ])
    |> foreign_key_constraint(:port_id)
    |> validate_required([:name, :port_id])
  end
end
