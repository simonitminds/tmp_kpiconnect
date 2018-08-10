defmodule Oceanconnect.Repo.Migrations.AddIsActiveToEverything do
  use Ecto.Migration

  def change do
		alter table(:users) do
			add :is_active, :boolean, default: true
		end

		alter table(:companies) do
			add :is_active, :boolean, default: true
		end

		alter table(:vessels) do
			add :is_active, :boolean, default: true
		end

		alter table(:ports) do
			add :is_active, :boolean, default: true
		end

		alter table(:barges) do
			add :is_active, :boolean, default: true
		end

		alter table(:fuels) do
			add :is_active, :boolean, default: true
		end
  end
end
