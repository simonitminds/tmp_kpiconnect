defmodule Oceanconnect.Repo.Migrations.AddClaimIdToFixtures do
  use Ecto.Migration

  def change do
    alter table(:auction_fixtures) do
      add :claim_id, references(:claims, on_delete: :nothing)
    end
  end
end
