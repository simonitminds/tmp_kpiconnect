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
alias Oceanconnect.Auctions.{Auction, Port, Vessel, Fuel}

Repo.delete_all(Auction)
Repo.delete_all(Port)
Repo.delete_all(Vessel)
Repo.delete_all(Fuel)

port1 = Port.changeset(%Port{}, %{name: "Algeciras", country: "Spain"}) |> Repo.insert!
Port.changeset(%Port{}, %{name: "Balboa", country: "Panama"}) |> Repo.insert!
Port.changeset(%Port{}, %{name: "Cristobal", country: "Panama"}) |> Repo.insert!
Port.changeset(%Port{}, %{name: "Dubai", country: "United Arab Emirates"}) |> Repo.insert!
Port.changeset(%Port{}, %{name: "Fujairah", country: "United Arab Emirates"}) |> Repo.insert!
Port.changeset(%Port{}, %{name: "Gibraltar", country: "Gibraltar"}) |> Repo.insert!
Port.changeset(%Port{}, %{name: "Hong Kong", country:	"China"}) |> Repo.insert!
Port.changeset(%Port{}, %{name: "Khor Fakkan", country:	"United Arab Emirates"}) |> Repo.insert!
Port.changeset(%Port{}, %{name: "Las Palmas", country: "Spain"}) |> Repo.insert!
Port.changeset(%Port{}, %{name: "Port Elizabeth", country: "South Africa"}) |> Repo.insert!
Port.changeset(%Port{}, %{name: "Port Gentil", country: "Gabon"}) |> Repo.insert!
Port.changeset(%Port{}, %{name: "Port Louis", country: "Mauritius"}) |> Repo.insert!
Port.changeset(%Port{}, %{name: "Santa Cruz de Tenerife", country: "Spain"}) |> Repo.insert!
Port.changeset(%Port{}, %{name: "Singapore", country: "Singapore"}) |> Repo.insert!
Port.changeset(%Port{}, %{name: "Skaw", country: "Denmark"}) |> Repo.insert!


vessel1 = Vessel.changeset(%Vessel{}, %{name: "Boaty McBoatFace", imo:	1234567})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "Hercules Voyager", imo:		9583732})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "LEO VOYAGER", imo:		9602473})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "LIBRA VOYAGER", imo:		9593206})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "Gaz Providence", imo:		9448504})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "LNG Abalamabie", imo:		9690171})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "LNG Adamawa ", imo:		9262211})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "LNG Akwa Ibom", imo:		9262209})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "LNG Bayelsa ", imo:		9241267})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "LNG Borno", imo:		9322803})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "LNG Cross River", imo:		9262223})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "LNG Enugu", imo:		9266994})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "LNG IMO", imo:		9311581})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "LNG Kano", imo:		9311567})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "LNG Lagos II ", imo:		9692014})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "LNG Lokoja", imo:		9269960})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "LNG Ogun", imo:		9322815})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "LNG Ondo", imo:		9311579})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "LNG Oyo", imo:		9267003})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "Lng Port-Harcourt II", imo:		9690157})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "LNG River Orashi", imo:		9266982})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "LNG RIVERS", imo:		9216298})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "LNG Sokoto", imo:		9216303})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "Aamira", imo:		9443401})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "Al Bahiya", imo:		9431147})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "Al Bidda", imo:		9132741})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "Al Dafna", imo:		9443683})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "Al Gattara", imo:		9337705})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "Al Ghariya", imo:		9337987})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "Al Gharrafa", imo:		9337717})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "Al Ghashamiya", imo:		9397286})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "Al Hamla", imo:		9337743})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "Al Huwaila", imo:		9360879})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "Al Jasra", imo:		9132791})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "Al Karaana", imo:		9431123})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "Al Kharaitiyat", imo:		9397327})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "Al Kharsaah", imo:		9360881})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "Al Khattiya", imo:		9431111})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "Al Khor", imo:		9085613})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "Al Mafyar", imo:		9397315})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "Al Nuaman", imo:		9431135})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "Al Rayyan", imo:		9086734})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "Al Rekayyat", imo:		9397339})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "Al Ruwais", imo:		9337951})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "Al Sadd", imo:		9397341})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "Al Safliya", imo:		9337963})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "Al Samriya", imo:		9388821})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "Al Shamal", imo:		9360893})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "Al Sheehaniya", imo:		9360831})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "Al Wajbah", imo:		9085625})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "Al Wakrah", imo:		9086746})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "Al Zubarah", imo:		9085649})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "Broog", imo:		9085651})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "Bu Samra", imo:		9388833})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "Doha", imo:		9085637})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "Duhail", imo:		9337975})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "Dukhan", imo:		9265500})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "Fraiha", imo:		9360817})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "Lijmiliya", imo:		9388819})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "Mesaimeer", imo:		9337729})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "Milaha Ras Laffan", imo:		9255854})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "Mozah", imo:		9337755})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "Onaiza", imo:		9397353})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "Rasheeda", imo:		9443413})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "Shagra", imo:		9418365})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "Tembek", imo:		9337731})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "Umm Al Amad", imo:		9360829})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "Umm Bab", imo:		9308431})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "Umm Slal", imo:		9525857})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "Zarga", imo:		9431214})  |> Repo.insert!
Vessel.changeset(%Vessel{}, %{name: "Zekreet", imo:		9132818})  |> Repo.insert!

fuel1 = Fuel.changeset(%Fuel{}, %{name: "MGO (DMA)"}) |> Repo.insert!
Fuel.changeset(%Fuel{}, %{name: "Gas Oil (Sul 0.10%)"}) |> Repo.insert!
Fuel.changeset(%Fuel{}, %{name: "RMG 380 - Sulphur max 3.50% (ISO 2005)"}) |> Repo.insert!
Fuel.changeset(%Fuel{}, %{name: "RMG 380 - Sulphur Max 3.50% (ISO 2010)"}) |> Repo.insert!
Fuel.changeset(%Fuel{}, %{name: "RMG 380 - Sulphur Max 3.50% (ISO 2012)"}) |> Repo.insert!


%Auction{}
|> Auction.changeset(%{vessel_id: vessel1.id, port_id: port1.id, fuel_id: fuel1.id, company: "Glencore", po: "1234567"})
|> Repo.insert()
