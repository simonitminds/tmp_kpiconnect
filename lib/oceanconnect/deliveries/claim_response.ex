defmodule Oceanconnect.Deliveries.ClaimResponse do
  use Ecto.Schema
  import Ecto.Changeset

  alias Oceanconnect.Accounts.User
  alias Oceanconnect.Auctions.{QuantityClaim}

  schema "claim_responses" do
    field(:content, :string)

    belongs_to(:author, User)
    belongs_to(:quantity_claim, QuantityClaim)

    timestamps()
  end

  @fields [
    :author_id,
    :content,
    :quantity_claim_id
  ]

  def changeset(%__MODULE__{} = response, attrs) do
    response
    |> cast(attrs, @fields)
    |> validate_claim()
    |> foreign_key_constraint(:quantity_claim_id)
    |> foreign_key_constraint(:author_id)
  end

  defp validate_claim(%Ecto.Changeset{} = changeset) do
    case get_field(changeset, :quantity_claim_id) do
      nil ->
        changeset
        |> add_error(:quantity_claim_id, "quantity_claim_id must be given")

      _ ->
        changeset
    end
  end
end
