defmodule Oceanconnect.Repo.Migrations.ConvertEventStorageEventColumnToBinary do
  use Ecto.Migration

  def up do
    alter table("auction_events") do
      remove :event
      add :event, :binary
    end
  end

  def down do
    alter table("auction_events") do
      remove :event
      add :event, :map
    end
  end
end
