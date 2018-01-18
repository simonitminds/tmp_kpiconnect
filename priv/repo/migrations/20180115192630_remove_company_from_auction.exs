defmodule Oceanconnect.Repo.Migrations.RemoveCompanyFromAuction do
  use Ecto.Migration

  def change do
    alter table(:auctions) do
      remove :company
    end
  end
end
