defmodule Oceanconnect.Repo.Migrations.CreateClaimResponses do
  use Ecto.Migration

  def change do
    create table(:claim_responses) do
      add(:content, :string)

      add(:author_id, references(:users))
      add(:quantity_claim_id, references(:claims))

      timestamps()
    end
  end
end
