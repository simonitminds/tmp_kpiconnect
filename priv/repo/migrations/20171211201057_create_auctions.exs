defmodule Oceanconnect.Repo.Migrations.CreateAuctions do
  use Ecto.Migration

  def change do
    create table(:auctions) do
      add :vessel, :string
      add :port, :string

      timestamps()
    end

  end
end
