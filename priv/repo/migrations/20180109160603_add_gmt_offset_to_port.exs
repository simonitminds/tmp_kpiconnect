defmodule Oceanconnect.Repo.Migrations.AddGmtOffsetToPort do
  use Ecto.Migration

  def change do
    alter table("ports") do
      add :gmt_offset, :integer
    end
  end
end
