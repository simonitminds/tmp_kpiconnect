defmodule Oceanconnect.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Oceanconnect.Repo

  alias Oceanconnect.Accounts.{Company, User}
  alias Oceanconnect.Auctions.{Barge}

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(User)
  end

  def list_users(params) do
    User
    |> Repo.paginate(params)
  end

  def list_active_users do
    User.select_active()
    |> Repo.all()
  end

  def list_admin_users do
    User.select_admins()
    |> Repo.all()
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  def get_active_user!(id) do
    User.select_active()
    |> Repo.get!(id)
  end

  def get_user_by_email(email), do: Repo.get_by(User, email: email)

  def get_user_name!(%User{} = user) do
    User.full_name(user)
  end

  def get_user_name!(id) do
    id
    |> get_user!()
    |> User.full_name()
  end

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def admin_create_user(attrs \\ %{}) do
    %User{}
    |> User.admin_changeset(attrs)
    |> Repo.insert()
  end

  def seed_user(attrs \\ %{}) do
    %User{}
    |> User.seed_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  def admin_update_user(%User{} = user, attrs) do
    user
    |> User.admin_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a User.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  def activate_user(user = %User{}) do
    user
    |> User.admin_changeset(%{is_active: true})
    |> Repo.update()
  end

  def deactivate_user(user = %User{}) do
    user
    |> User.admin_changeset(%{is_active: false})
    |> Repo.update()
  end

  def reset_password(%User{} = user, attrs) do
    user
    |> User.password_reset_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{source: %User{}}

  """
  def change_user(%User{} = user) do
    User.changeset(user, %{})
  end

  def change_user_password(%User{} = user) do
    User.password_reset_changeset(user, %{})
  end

  def verify_login(%{"email" => email, "password" => password}) do
    # TODO: don't pass comeonin error message to end user
    case Repo.get_by(User, email: String.upcase(email)) do
      nil -> {:error, "Invalid email/password"}
      user -> Comeonin.Bcrypt.check_pass(user, password)
    end
  end

  def verify_login(_), do: {:error, "Invalid email/password"}

  def load_company_on_user(%User{} = user), do: Repo.preload(user, [:company])

  @doc """
  Returns the list of companies.

  ## Examples

      iex> list_companies()
      [%Company{}, ...]

  """
  def list_companies do
    Repo.all(Company)
  end

  def list_companies(params) do
    Company
    |> Repo.paginate(params)
  end

  def list_broker_entities do
    Company.select_brokers()
    |> Repo.all()
  end

  def list_companies_by_ids(ids) do
    ids
    |> Company.by_ids()
    |> Repo.all()
  end

  def list_active_companies do
    Company.select_active()
    |> Repo.all()
  end

  def users_for_companies(companies) when is_list(companies) do
    Enum.map(companies, & &1.id)
    |> User.for_companies()
    |> User.select_active()
    |> Repo.all()
  end

  @doc """
  Gets a single company.

  Raises `Ecto.NoResultsError` if the Company does not exist.

  ## Examples

      iex> get_company!(123)
      %Company{}

      iex> get_company!(456)
      ** (Ecto.NoResultsError)

  """
  def get_company!(id), do: Repo.get!(Company, id)

  def get_active_company!(id) do
    Company.select_active()
    |> Repo.get!(id)
  end

  def get_ocm_company, do: Repo.get_by!(Company, is_ocm: true)

  @doc """
  Creates a company.

  ## Examples

      iex> create_company(%{field: value})
      {:ok, %Company{}}

      iex> create_company(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_company(attrs \\ %{}) do
    %Company{}
    |> Company.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a company.

  ## Examples

      iex> update_company(company, %{field: new_value})
      {:ok, %Company{}}

      iex> update_company(company, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_company(%Company{} = company, attrs) do
    company
    |> Company.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Company.

  ## Examples

      iex> delete_company(company)
      {:ok, %Company{}}

      iex> delete_company(company)
      {:error, %Ecto.Changeset{}}

  """
  def delete_company(%Company{} = company) do
    Repo.delete(company)
  end

  def activate_company(company = %Company{}) do
    company
    |> Company.changeset(%{is_active: true})
    |> Repo.update()
  end

  def deactivate_company(company = %Company{}) do
    company
    |> Company.changeset(%{is_active: false})
    |> Repo.update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking company changes.

  ## Examples

      iex> change_company(company)
      %Ecto.Changeset{source: %Company{}}

  """
  def change_company(%Company{} = company) do
    Company.changeset(company, %{})
  end

  def add_port_to_company(%Company{} = company, %Oceanconnect.Auctions.Port{} = port) do
    company_with_ports =
      company
      |> Repo.preload(:ports)

    company_with_ports
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:ports, [port | company_with_ports.ports])
    |> Repo.update!()
  end

  def set_ports_on_company(%Company{} = company, ports) when is_list(ports) do
    company
    |> Repo.preload(:ports)
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:ports, ports)
    |> Repo.update!()
  end

  @doc """
  Returns true when the given user belongs to the company with the given id.
  """
  def authorized_for_company?(nil, _company_id), do: false
  def authorized_for_company?(_user, nil), do: false
  def authorized_for_company?(%User{company_id: company_id}, company_id), do: true
  def authorized_for_company?(_, _), do: false

  @doc """
  Returns a list of Barges that are associated to the company with the given
  id. If no barges are associated with the company, an empty list is returned.
  """
  def list_company_barges(company_id) do
    company_id
    |> Barge.by_company()
    |> Barge.select_active()
    |> Repo.all()
    |> Repo.preload(:port)
  end

  def impersonable_users_for(%User{is_admin: true}) do
    User.select_active()
    |> User.impersonable_users()
    |> Repo.all()
    |> Repo.preload(:company)
  end

  def impersonable_users_for(_user), do: []
end
