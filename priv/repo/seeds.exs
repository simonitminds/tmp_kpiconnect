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

port1 = Port.changeset(%Port{}, %{name: "Singapore"}) |> Repo.insert!
port2 = Port.changeset(%Port{}, %{name: "Boston"}) |> Repo.insert


%Auction{}
|> Auction.changeset(%{vessel: "Boaty McBoatface", port_id: port1.id, company: "Glencore", po: "1234567"})
|> Repo.insert()
