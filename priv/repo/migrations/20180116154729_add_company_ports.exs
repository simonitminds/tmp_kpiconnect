defmodule Oceanconnect.Repo.Migrations.AddCompanyPorts do
  use Ecto.Migration

  def change do
    create table(:company_ports, primary_key: false) do
      add :company_id, references(:companies)
      add :port_id, references(:ports)
    end
    create unique_index(:company_ports, [:company_id, :port_id], name: :unique_company_port)
  end
end
