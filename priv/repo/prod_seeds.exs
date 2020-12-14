# Script for populating the database. You can run it as:
#
#   mix run priv/repo/prod_seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#   Oceanconnect.Repo.insert!(%Oceanconnect.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Oceanconnect.Repo
alias Oceanconnect.Accounts
alias Oceanconnect.Accounts.{Company, User}


ocm_params = %{
  name: "Ocean Connect Marine",
  address1: "",
  address2: "",
  city: "London",
  is_supplier: true,
  country: "Britain",
  contact_name: "Neal Bolton",
  email: "nbol@KPIocean.com",
  main_phone: "",
  mobile_phone: "",
  postal_code: ""
}

ocm = Repo.get_or_insert!(Company, ocm_params)

user_params = %{
  email: "NBOL@KPIOCEAN.COM",
  is_admin: true,
  first_name: "Neal",
  last_name: "Bolton",
  password: "ocmtest",
  company_id: ocm.id
}

{:ok, neal} = Oceanconnect.Accounts.create_user(user_params)
