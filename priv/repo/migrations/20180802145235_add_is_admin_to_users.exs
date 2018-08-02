defmodule Oceanconnect.Repo.Migrations.AddIsAdminToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :is_admin, :bool, default: false
    end
  end
end
