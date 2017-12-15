defmodule Oceanconnect.Repo.Migrations.ChangePortToForeignKey do
  use Ecto.Migration

  def up do
    alter table("auctions") do
      remove :port
      add :port_id, references(:ports)
    end
  end

  def down do
    alter table("auctions") do
      remove :port_id
      add :port, :string
    end
  end
  
end
