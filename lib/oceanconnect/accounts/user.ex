defmodule Oceanconnect.Accounts.User do
  use Ecto.Schema
  import Ecto.{Changeset, Query}
  alias Oceanconnect.Accounts.User

  @derive {Poison.Encoder, only: [:email, :company]}

  schema "users" do
    field(:email, :string)
    field(:first_name, :string)
    field(:last_name, :string)
    field(:password_hash, :string)
    field(:password, :string, virtual: true)
    field(:is_admin, :boolean, default: false)
    field(:is_active, :boolean, default: true)
    field(:impersonated_by, :integer, virtual: true)
    belongs_to(:company, Oceanconnect.Accounts.Company)

    timestamps()
  end

  @doc false
  def changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:email, :first_name, :last_name, :password, :company_id, :is_admin])
    |> validate_required([:email, :password, :company_id])
    |> foreign_key_constraint(:company_id)
    |> unique_constraint(:email)
    |> put_pass_hash()
  end

  def admin_changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:is_active])
  end

  def impersonable_users(query \\ User) do
    from(
      q in query,
      where: q.is_admin == false,
      preload: [:company]
    )
  end

  defp put_pass_hash(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
    change(changeset, Comeonin.Bcrypt.add_hash(password))
  end

  defp put_pass_hash(changeset), do: changeset

	def select_active(query \\ User) do
		from q in query,
		where: q.is_active == true
	end

	def for_companies(company_ids) when is_list(company_ids) do
		from u in User,
		  where: u.company_id in ^company_ids
	end

	defimpl Bamboo.Formatter, for: User do
		def format_email_address(%User{first_name: first_name, last_name: last_name, email: email}, opts \\ []) do
			full_name = "#{first_name} #{last_name}"
			{full_name, email}
		end
	end
end
