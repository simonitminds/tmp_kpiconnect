defmodule Oceanconnect.Repo.Migrations.AddOfficeAndMobilePhoneToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :office_phone, :string
      add :mobile_phone, :string
    end
  end
end
