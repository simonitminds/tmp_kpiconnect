defmodule Oceanconnect.Repo.Migrations.AddIsObserverToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :is_observer, :boolean, default: false
    end
  end
end
