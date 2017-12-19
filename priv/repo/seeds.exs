# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Oceanconnect.Repo.insert!(%Oceanconnect.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Oceanconnect.Repo
alias Oceanconnect.Auctions.{Auction, Port}

Repo.delete_all(Auction)
Repo.delete_all(Port)

port1 = Port.changeset(%Port{}, %{name: "Algeciras", country: "Spain"}) |> Repo.insert!
port2 = Port.changeset(%Port{}, %{name: "Balboa", country: "Panama"}) |> Repo.insert!
port3 = Port.changeset(%Port{}, %{name: "Cristobal", country: "Panama"}) |> Repo.insert!
port4 = Port.changeset(%Port{}, %{name: "Dubai", country: "United Arab Emirates"}) |> Repo.insert!
port5 = Port.changeset(%Port{}, %{name: "Fujairah", country: "United Arab Emirates"}) |> Repo.insert!
port6 = Port.changeset(%Port{}, %{name: "Gibraltar", country: "Gibraltar"}) |> Repo.insert!
port7 = Port.changeset(%Port{}, %{name: "Hong Kong", country:	"China"}) |> Repo.insert!
port8 = Port.changeset(%Port{}, %{name: "Khor Fakkan", country:	"United Arab Emirates"}) |> Repo.insert!
port9 = Port.changeset(%Port{}, %{name: "Las Palmas", country: "Spain"}) |> Repo.insert!
port10 = Port.changeset(%Port{}, %{name: "Port Elizabeth", country: "Sout Africa"}) |> Repo.insert!
port11 = Port.changeset(%Port{}, %{name: "Port Gentil", country: "Gabon"}) |> Repo.insert!
port12 = Port.changeset(%Port{}, %{name: "Port Louis", country: "Mauritius"}) |> Repo.insert!
port13 = Port.changeset(%Port{}, %{name: "Santa Cruz de Tenerife", country: "Spain"}) |> Repo.insert!
port14 = Port.changeset(%Port{}, %{name: "Singapore", country: "Singapore"}) |> Repo.insert!
port15 = Port.changeset(%Port{}, %{name: "Skaw", country: "Denmark"}) |> Repo.insert!


%Auction{}
|> Auction.changeset(%{vessel: "Boaty McBoatface", port_id: port1.id, company: "Glencore", po: "1234567"})
|> Repo.insert()
