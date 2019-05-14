defmodule Oceanconnect.Deliveries.ClaimResponse do
  use Ecto.Schema
  import Ecto.Changeset

  alias Oceanconnect.Accounts.User
  alias Oceanconnect.Deliveries.Claim

  schema "claim_responses" do
    field(:content, :string)

    belongs_to(:author, User)
    belongs_to(:claim, Claim)

    timestamps()
  end

  @fields [
    :author_id,
    :content,
    :claim_id
  ]

  def changeset(%__MODULE__{} = response, attrs) do
    response
    |> cast(attrs, @fields)
    |> validate_required([:author_id, :claim_id])
    |> foreign_key_constraint(:claim_id)
    |> foreign_key_constraint(:author_id)
  end
end
