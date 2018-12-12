defmodule Oceanconnect.Repo.Migrations.AddIsBrokerAndBrokerEntityToCompanies do
  use Ecto.Migration

  def change do
    alter table("companies") do
      add :broker_entity_id, references(:companies)
      add :is_broker, :boolean
    end
  end
end
