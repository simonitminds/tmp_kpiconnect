defmodule Oceanconnect.Repo.Migrations.ConvertMessagesToText do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      modify :content, :text
    end
  end
end
