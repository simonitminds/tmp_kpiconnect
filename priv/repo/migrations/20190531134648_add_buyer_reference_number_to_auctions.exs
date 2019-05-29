defmodule Oceanconnect.Repo.Migrations.AddBuyerReferenceNumberToAuctions do
  use Ecto.Migration

  def change do
    alter table(:auctions) do
      add :buyer_reference_number, :string
    end
  end
end
