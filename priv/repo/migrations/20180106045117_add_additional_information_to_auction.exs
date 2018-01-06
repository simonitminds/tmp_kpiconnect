defmodule Oceanconnect.Repo.Migrations.AddAdditionalInformationToAuction do
  use Ecto.Migration

  def change do
    alter table("auctions") do
      add :additional_information, :text
    end
  end
end
