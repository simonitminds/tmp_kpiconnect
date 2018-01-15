defmodule Oceanconnect.Repo.Migrations.AddCompanyToUserAndVessel do
  use Ecto.Migration

  def up do
    alter table("users") do
      add :company_id, references(:companies)
    end

    alter table("vessels") do
      add :company_id, references(:companies)
    end
  end
end
