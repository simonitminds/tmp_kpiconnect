defmodule Oceanconnect.Repo.Migrations.AddOtherClaimTypeFieldsToClaims do
  use Ecto.Migration

  def change do
    alter table(:claims) do
      add(:quantity_difference, :decimal)
      add(:quality_description, :string)
    end
  end
end
