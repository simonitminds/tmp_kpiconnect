defmodule Oceanconnect.Repo.Migrations.AddPortAgentToAuction do
  use Ecto.Migration

  def change do
    alter table(:auctions) do
      add :port_agent, :string
    end
  end
end
