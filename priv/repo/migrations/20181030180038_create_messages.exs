defmodule Oceanconnect.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages) do
      add :content, :string
      add :has_been_seen, :boolean, default: false, null: false
      add :auction_id, references(:auctions, on_delete: :nothing)
      add :author_id, references(:users, on_delete: :nothing)
      add :author_company_id, references(:companies, on_delete: :nothing)
      add :recipient_company_id, references(:companies, on_delete: :nothing)

      timestamps()
    end

    create index(:messages, [:auction_id])
    create index(:messages, [:author_id])
    create index(:messages, [:author_company_id])
    create index(:messages, [:recipient_company_id])
  end
end
