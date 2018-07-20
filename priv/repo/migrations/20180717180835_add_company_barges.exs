defmodule Oceanconnect.Repo.Migrations.AddCompanyBarges do
  use Ecto.Migration

  def change do
    create table "company_barges" do
      add :company_id, references("companies")
      add :barge_id, references("barges")
    end
  end
end
