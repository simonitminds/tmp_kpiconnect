defmodule Oceanconnect.Repo.Migrations.CreateFuels do
  use Ecto.Migration

  def change do
    create table(:fuels) do
      add :name, :string

      timestamps()
    end

  end
end
