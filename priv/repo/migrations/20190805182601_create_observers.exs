defmodule Oceanconnect.Repo.Migrations.CreateObservers do
  use Ecto.Migration

  def change do
    create table(:observers) do
      add :user_id, references(:users, on_delete: :nothing)
      add :auction_id, references(:auctions, on_delete: :nothing)
      add :term_auction_id, references(:auctions, on_delete: :nothing)

      timestamps()
    end
  end
end
