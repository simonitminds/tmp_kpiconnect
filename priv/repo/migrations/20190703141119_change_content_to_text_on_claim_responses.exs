defmodule Oceanconnect.Repo.Migrations.ChangeContentToTextOnClaimResponses do
  use Ecto.Migration

  def change do
    alter table(:claim_responses) do
      modify :content, :text
    end
  end
end
