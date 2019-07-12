defmodule Oceanconnect.Repo.Migrations.ChangeFixtureQuantitiesToDecimal do
  use Ecto.Migration

  def change do
    alter table(:auction_fixtures) do
      modify :quantity, :decimal
      modify :original_quantity, :decimal
      modify :delivered_quantity, :decimal
    end
  end
end
