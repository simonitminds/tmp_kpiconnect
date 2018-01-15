defmodule Oceanconnect.Accounts.UserProfile do
  use Ecto.Schema
  import Ecto.Changeset
  alias Oceanconnect.Accounts.{UserProfile, User}


  schema "user_profiles" do
    field :email, :string
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(%UserProfile{} = profile, attrs) do
    profile
    |> cast(attrs, [:email, :user_id])
    |> validate_required([:user_id])
    |> foreign_key_constraint(:user_id)
  end
end
