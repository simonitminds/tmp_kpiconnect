defmodule Oceanconnect.Accounts.Company do
  use Ecto.Schema
  import Ecto.{Changeset, Query}
  alias Oceanconnect.Accounts.Company

  @derive {Poison.Encoder, except: [:__meta__, :barges, :users, :vessels, :ports, :broker_entity]}

  schema "companies" do
    field(:address1, :string)
    field(:address2, :string)
    field(:city, :string)
    field(:contact_name, :string)
    field(:country, :string)
    field(:credit_margin_amount, :float)
    field(:email, :string)
    field(:is_active, :boolean, default: true)
    field(:is_broker, :boolean, default: false)
    field(:is_supplier, :boolean, default: false)
    field(:is_ocm, :boolean, default: false)
    field(:main_phone, :string)
    field(:mobile_phone, :string)
    field(:name, :string)
    field(:postal_code, :string)
    belongs_to(:broker_entity, Company)

    many_to_many(
      :barges,
      Oceanconnect.Auctions.Barge,
      join_through: "company_barges",
      on_replace: :delete,
      on_delete: :delete_all
    )

    has_many(:users, Oceanconnect.Accounts.User, on_replace: :delete)
    has_many(:vessels, Oceanconnect.Auctions.Vessel, on_replace: :delete)

    many_to_many(
      :ports,
      Oceanconnect.Auctions.Port,
      join_through: "company_ports",
      on_replace: :delete,
      on_delete: :delete_all
    )

    timestamps()
  end

  @required_fields [
    :name
  ]

  @optional_fields [
    :address1,
    :address2,
    :broker_entity_id,
    :city,
    :contact_name,
    :country,
    :credit_margin_amount,
    :email,
    :is_active,
    :is_broker,
    :is_supplier,
    :is_ocm,
    :main_phone,
    :mobile_phone,
    :postal_code
  ]

  @doc false
  def changeset(%Company{} = company, attrs) do
    company
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> maybe_set_credit_margin_amount_to_nil
  end

  def alphabetical(query \\ Company), do: order_by(query, :name)

  def select_active(query \\ Company), do: query |> alphabetical() |> where(is_active: true)

  def select_brokers(query \\ Company), do: query |> alphabetical() |> where(is_broker: true)

  def by_ids(ids, query \\ Company) when is_list(ids), do: where(query, [c], c.id in ^ids)

  defp maybe_set_credit_margin_amount_to_nil(changeset) do
    case get_change(changeset, :credit_margin_amount) do
      0.0 -> put_change(changeset, :credit_margin_amount, nil)
      _ -> changeset
    end
  end
end
