defmodule Oceanconnect.Repo.Migrations.ChangeQuantityMissingOnClaims do
  use Ecto.Migration

  def change do
    alter table(:claims) do
      modify :quantity_missing, :decimal
    end
  end
end
