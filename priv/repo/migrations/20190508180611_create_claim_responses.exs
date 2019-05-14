defmodule Oceanconnect.Repo.Migrations.CreateClaimResponses do
  use Ecto.Migration

  def change do
    create table(:claim_responses) do
      add(:content, :string)

      add(:author_id, references(:users))
      add(:claim_id, references(:claims))

      timestamps()
    end
  end
end
