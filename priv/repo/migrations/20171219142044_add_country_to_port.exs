defmodule Oceanconnect.Repo.Migrations.AddCountryToPort do
  use Ecto.Migration

  def change do
    alter table("ports") do
      add :country, :string
    end
  end
end
