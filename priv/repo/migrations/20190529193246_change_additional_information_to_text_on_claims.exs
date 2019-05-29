defmodule Oceanconnect.Repo.Migrations.ChangeAdditionalInformationToTextOnClaims do
  use Ecto.Migration

  def change do
    alter table(:claims) do
      modify :additional_information, :text
    end
  end
end
