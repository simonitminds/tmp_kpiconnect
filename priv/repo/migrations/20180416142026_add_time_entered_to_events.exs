defmodule Oceanconnect.Repo.Migrations.AddTimeEnteredToEvents do
  use Ecto.Migration

  def change do
    alter table(:auction_events) do
      add :time_entered, :naive_datetime
    end
  end
end
