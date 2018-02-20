defmodule Oceanconnect.Repo.Migrations.ChangeFromUserToCompanyOnAuction do
  use Ecto.Migration

  def up do
    alter table(:auction_suppliers) do
      remove :supplier_id
      add :supplier_id, references(:companies, on_delete: :nothing)
    end
  end

  def down do
    alter table(:auction_suppliers) do
      remove :supplier_id
      add :supplier_id, references(:users, on_delete: :nothing)
    end
  end
end
