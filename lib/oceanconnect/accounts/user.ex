defmodule Oceanconnect.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias Oceanconnect.Accounts.User

  @derive {Poison.Encoder, except: [:__meta__]}

  schema "users" do
    field :email, :string
    field :password_hash, :string
    field :password, :string, virtual: true
    belongs_to :company, Oceanconnect.Accounts.Company

    timestamps()
  end

  @doc false
  def changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:email, :password, :company_id])
    |> validate_required([:email, :password])
    |> foreign_key_constraint(:company_id)
    |> unique_constraint(:email)
    |> put_pass_hash()
  end

  defp put_pass_hash(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
    change(changeset, Comeonin.Bcrypt.add_hash(password))
  end
  defp put_pass_hash(changeset), do: changeset
end
