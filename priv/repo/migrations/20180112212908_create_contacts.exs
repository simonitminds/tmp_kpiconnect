defmodule Oceanconnect.Repo.Migrations.CreateContacts do
  use Ecto.Migration

  def change do
    create table(:contacts) do
      add :address1, :string
      add :address2, :string
      add :city, :string
      add :country, :string
      add :email, :string
      add :main_phone, :string
      add :mobile_phone, :string
      add :name, :string
      add :postal_code, :integer

      timestamps()
    end
  end
end
