defmodule Oceanconnect.Repo.Migrations.CreateVessels do
  use Ecto.Migration

  def change do
    create table(:vessels) do
      add :name, :string
      add :imo, :integer

      timestamps()
    end

  end
end
