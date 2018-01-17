defmodule Oceanconnect.Repo do
  use Ecto.Repo, otp_app: :oceanconnect

  @doc """
  Dynamically loads the repository url from the
  DATABASE_URL environment variable.
  """
  def init(_, opts) do
    {:ok, Keyword.put(opts, :url, System.get_env("DATABASE_URL"))}
  end

  def get_or_insert!(module, map) do
    clean_map = Enum.reject(map, fn({_k, v}) -> v == nil or v == "" end) |> Enum.into(%{})
    result = Oceanconnect.Repo.get_by(module, clean_map)
    if result do
      result
    else
      module.changeset(struct(module, %{}), clean_map)
      |> Oceanconnect.Repo.insert_or_update!
    end
  end

  def get_or_insert_user!(nil, email, company) do
    {:ok, user} = Oceanconnect.Accounts.create_user(%{email: email, password: "password", company_id: company.id})
    user
  end
  def get_or_insert_user!(user, _email, _company), do: user
end
