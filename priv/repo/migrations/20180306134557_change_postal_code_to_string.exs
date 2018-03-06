defmodule Oceanconnect.Repo.Migrations.ChangePostalCodeToString do
  use Ecto.Migration

  def up do
    alter table("companies") do
      modify :postal_code, :string
    end
  end

  def down do
    alter table("companies") do
      modify :postal_code, :integer
    end
  end
end
