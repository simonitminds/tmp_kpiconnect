defmodule Oceanconnect.Accounts.Company do
  use Ecto.Schema
  import Ecto.Changeset
  alias Oceanconnect.Accounts.Company

  @derive {Poison.Encoder, except: [:__meta__, :users, :vessels, :ports]}

  schema "companies" do
    field :address1, :string
    field :address2, :string
    field :city, :string
    field :contact_name, :string
    field :country, :string
    field :email, :string
    field :name, :string
    field :main_phone, :string
    field :mobile_phone, :string
    field :postal_code, :string
    field :is_supplier, :boolean, default: false
    has_many :barges, through: [:company_barges, :barges]
    has_many :users, Oceanconnect.Accounts.User, on_replace: :delete
    has_many :vessels, Oceanconnect.Auctions.Vessel, on_replace: :delete
    many_to_many :ports, Oceanconnect.Auctions.Port, join_through: "company_ports", on_replace: :delete

    timestamps()
  end

  @required_fields [
    :name
  ]

  @optional_fields [
    :address1,
    :address2,
    :city,
    :contact_name,
    :country,
    :email,
    :main_phone,
    :mobile_phone,
    :postal_code,
    :is_supplier
  ]

  @doc false
  def changeset(%Company{} = company, attrs) do
    company
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
