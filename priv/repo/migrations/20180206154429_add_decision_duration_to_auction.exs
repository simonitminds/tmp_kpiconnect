defmodule Oceanconnect.Repo.Migrations.AddDecisionDurationToAuction do
  use Ecto.Migration

  def change do
    alter table("auctions") do
      add :decision_duration, :integer
    end
  end
end
