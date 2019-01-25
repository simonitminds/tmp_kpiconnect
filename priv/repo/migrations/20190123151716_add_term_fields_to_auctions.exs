defmodule Oceanconnect.Repo.Migrations.AddTermFieldsToAuctions do
  use Ecto.Migration

  def change do
    alter table(:auctions) do
      add(:type, :string)
    end
  end
end
