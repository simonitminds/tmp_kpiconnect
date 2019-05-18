defmodule Oceanconnect.Repo.Migrations.ChangeClaimIdOnClaimResponses do
  use Ecto.Migration

  def change do
    alter table(:claim_responses) do
      remove(:quantity_claim_id)
      add(:claim_id, references(:claims))
    end
  end
end
