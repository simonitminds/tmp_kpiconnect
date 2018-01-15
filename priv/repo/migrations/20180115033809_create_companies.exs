defmodule Oceanconnect.Repo.Migrations.CreateCompanies do
  use Ecto.Migration

  def change do
    create table(:companies) do
      add :address1, :string
      add :address2, :string
      add :city, :string
      add :contact_name, :string
      add :country, :string
      add :email, :string
      add :name, :string
      add :main_phone, :string
      add :mobile_phone, :string
      add :postal_code, :integer

      timestamps()
    end

    create unique_index(:companies, [:name])
  end
end
