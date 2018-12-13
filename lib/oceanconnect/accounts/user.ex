defmodule Oceanconnect.Accounts.User do
  use Ecto.Schema
  import Ecto.{Changeset, Query}
  alias Oceanconnect.Accounts.{User, Company}

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
    |> upcase_email()
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
      join: c in Company,
      where: c.id == q.company_id,
      order_by: [asc: c.name, asc: q.first_name, asc: q.last_name],
      preload: [:company]
    )
  end

  defp put_pass_hash(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
    change(changeset, Comeonin.Bcrypt.add_hash(password))
  end

  defp put_pass_hash(changeset), do: changeset

  defp upcase_email(%Ecto.Changeset{valid?: true, changes: %{email: email}} = changeset) do
    change(changeset, %{email: String.upcase(email)})
  end

  defp upcase_email(changeset), do: changeset

  def select_active(query \\ User) do
    from(
      q in query,
      where: q.is_active == true
    )
  end

  def select_admins(query \\ User) do
    from(
      q in query,
      where: q.is_admin == true
    )
  end

  def for_companies(company_ids) when is_list(company_ids) do
    from(
      u in User,
      where: u.company_id in ^company_ids
    )
  end

  def full_name(%User{first_name: first_name, last_name: last_name}) do
    "#{first_name} #{last_name}"
  end

  defimpl Bamboo.Formatter, for: User do
    def format_email_address(user = %User{email: email}, _opts \\ []) do
      {User.full_name(user), email}
    end
  end
end
