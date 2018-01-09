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
    result = Oceanconnect.Repo.get_by(module, map)
    if result do
      result
    else
      module.changeset(struct(module, %{}), map)
      |> Oceanconnect.Repo.insert_or_update!
    end
  end
end
