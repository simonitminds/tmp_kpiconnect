defmodule Oceanconnect.Accounts.User do
  use Ecto.Schema
  import Ecto.{Changeset, Query}
  alias Oceanconnect.Accounts.{User, Company}
  alias Oceanconnect.Deliveries.ClaimResponse

  @derive {Poison.Encoder, only: [:email, :company, :first_name, :last_name, :id]}

  schema "users" do
    field(:email, :string)
    field(:office_phone, :string)
    field(:mobile_phone, :string)
    field(:first_name, :string)
    field(:last_name, :string)
    field(:password_hash, :string)
    field(:password, :string, virtual: true)
    field(:has_2fa, :boolean, default: false)
    field(:is_observer, :boolean, default: false)
    field(:is_admin, :boolean, default: false)
    field(:is_active, :boolean, default: true)
    field(:impersonated_by, :integer, virtual: true)
    belongs_to(:company, Oceanconnect.Accounts.Company)
    has_many(:claim_responses, ClaimResponse)

    timestamps()
  end

  @doc false
  def changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:email, :first_name, :last_name, :office_phone, :mobile_phone, :has_2fa])
    |> validate_required([:email])
    |> upcase_email()
    |> unique_constraint(:email)
  end

  def admin_changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [
      :email,
      :first_name,
      :last_name,
      :office_phone,
      :mobile_phone,
      :is_active,
      :company_id,
      :is_admin,
      :has_2fa,
      :is_observer
    ])
    |> validate_required([:email, :company_id])
    |> foreign_key_constraint(:company_id)
    |> upcase_email()
    |> unique_constraint(:email)
  end

  def seed_changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [
      :email,
      :first_name,
      :last_name,
      :office_phone,
      :mobile_phone,
      :is_active,
      :company_id,
      :is_admin,
      :password,
      :is_observer
    ])
    |> foreign_key_constraint(:company_id)
    |> upcase_email()
    |> unique_constraint(:email)
    |> put_pass_hash()
  end

  def password_reset_changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:password])
    |> validate_required([:password])
    |> validate_confirmation(:password, message: "Passwords do not match")
    |> validate_length(:password, min: 6)
    |> put_pass_hash()
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

  def alphabetical(query \\ User), do: order_by(query, :last_name)

  def select_active(query \\ User), do: query |> alphabetical() |> where(is_active: true)

  def select_admins(query \\ User), do: query |> alphabetical() |> where(is_admin: true)

  def select_observers(query \\ User), do: query |> alphabetical() |> where(is_observer: true)

  def for_companies(company_ids) when is_list(company_ids),
    do: where(User, [u], u.company_id in ^company_ids)

  def with_company(user = %User{}), do: Oceanconnect.Repo.preload(user, :company)

  def full_name(%User{first_name: first_name, last_name: last_name}),
    do: "#{first_name} #{last_name}"

  def email_exists?(email),
    do: if(Oceanconnect.Repo.get_by(User, email: String.upcase(email)), do: true, else: false)

  defimpl Bamboo.Formatter, for: User do
    def format_email_address(user = %User{email: email}, _opts \\ []) do
      {User.full_name(user), email}
    end
  end

  defp put_pass_hash(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
    change(changeset, Bcrypt.add_hash(password))
  end

  defp put_pass_hash(changeset), do: changeset

  defp upcase_email(%Ecto.Changeset{valid?: true, changes: %{email: email}} = changeset) do
    change(changeset, %{email: String.upcase(email)})
  end

  defp upcase_email(changeset), do: changeset
end
