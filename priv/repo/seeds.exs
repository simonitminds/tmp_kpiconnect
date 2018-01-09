# Script for populating the database. You can run it as:
#
#   mix run priv/repo/seeds.exs
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
alias Oceanconnect.Accounts.User
alias Oceanconnect.Auctions.{Auction, Fuel, Port, Vessel}


user = case Repo.get_by(User, %{email: "test@example.com"}) do
  user -> user
  _ -> Accounts.create_user(%{email: "test@example.com", name: "test", password: "password"})
end

[
  %{name: "Algeciras", country: "Spain", gmt_offset: 1},
  %{name: "Balboa", country: "Panama", gmt_offset: -5},
  %{name: "Cristobal", country: "Panama", gmt_offset: -5},
  %{name: "Dubai", country: "United Arab Emirates", gmt_offset: 4},
  %{name: "Fujairah", country: "United Arab Emirates", gmt_offset: 4},
  %{name: "Gibraltar", country: "Gibraltar", gmt_offset: 1},
  %{name: "Hong Kong", country:	"China", gmt_offset: 8},
  %{name: "Khor Fakkan", country:	"United Arab Emirates", gmt_offset: 4},
  %{name: "Las Palmas", country: "Spain", gmt_offset: 0},
  %{name: "Port Elizabeth", country: "South Africa", gmt_offset: 2},
  %{name: "Port Gentil", country: "Gabon", gmt_offset: 1},
  %{name: "Port Louis", country: "Mauritius", gmt_offset: 4},
  %{name: "Santa Cruz de Tenerife", country: "Spain", gmt_offset: 0},
  %{name: "Singapore", country: "Singapore", gmt_offset: 8},
  %{name: "Skaw", country: "Denmark", gmt_offset: 1}
]
|> Enum.map(fn(port) ->
  Repo.get_or_insert!(Port, port)
end)

[
  %{name: "Hercules Voyager", imo: 9583732},
  %{name: "LEO VOYAGER", imo: 9602473},
  %{name: "LIBRA VOYAGER", imo: 9593206},
  %{name: "Gaz Providence", imo: 9448504},
  %{name: "LNG Abalamabie", imo: 9690171},
  %{name: "LNG Adamawa ", imo: 9262211},
  %{name: "LNG Akwa Ibom", imo: 9262209},
  %{name: "LNG Bayelsa ", imo: 9241267},
  %{name: "LNG Borno", imo: 9322803},
  %{name: "LNG Cross River", imo: 9262223},
  %{name: "LNG Enugu", imo: 9266994},
  %{name: "LNG IMO", imo: 9311581},
  %{name: "LNG Kano", imo: 9311567},
  %{name: "LNG Lagos II ", imo: 9692014},
  %{name: "LNG Lokoja", imo: 9269960},
  %{name: "LNG Ogun", imo: 9322815},
  %{name: "LNG Ondo", imo: 9311579},
  %{name: "LNG Oyo", imo: 9267003},
  %{name: "Lng Port-Harcourt II", imo: 9690157},
  %{name: "LNG River Orashi", imo: 9266982},
  %{name: "LNG RIVERS", imo: 9216298},
  %{name: "LNG Sokoto", imo: 9216303},
  %{name: "Aamira", imo: 9443401},
  %{name: "Al Bahiya", imo: 9431147},
  %{name: "Al Bidda", imo: 9132741},
  %{name: "Al Dafna", imo: 9443683},
  %{name: "Al Gattara", imo: 9337705},
  %{name: "Al Ghariya", imo: 9337987},
  %{name: "Al Gharrafa", imo: 9337717},
  %{name: "Al Ghashamiya", imo: 9397286},
  %{name: "Al Hamla", imo: 9337743},
  %{name: "Al Huwaila", imo: 9360879},
  %{name: "Al Jasra", imo: 9132791},
  %{name: "Al Karaana", imo: 9431123},
  %{name: "Al Kharaitiyat", imo: 9397327},
  %{name: "Al Kharsaah", imo: 9360881},
  %{name: "Al Khattiya", imo: 9431111},
  %{name: "Al Khor", imo: 9085613},
  %{name: "Al Mafyar", imo: 9397315},
  %{name: "Al Nuaman", imo: 9431135},
  %{name: "Al Rayyan", imo: 9086734},
  %{name: "Al Rekayyat", imo: 9397339},
  %{name: "Al Ruwais", imo: 9337951},
  %{name: "Al Sadd", imo: 9397341},
  %{name: "Al Safliya", imo: 9337963},
  %{name: "Al Samriya", imo: 9388821},
  %{name: "Al Shamal", imo: 9360893},
  %{name: "Al Sheehaniya", imo: 9360831},
  %{name: "Al Wajbah", imo: 9085625},
  %{name: "Al Wakrah", imo: 9086746},
  %{name: "Al Zubarah", imo: 9085649},
  %{name: "Broog", imo: 9085651},
  %{name: "Bu Samra", imo: 9388833},
  %{name: "Doha", imo: 9085637},
  %{name: "Duhail", imo: 9337975},
  %{name: "Dukhan", imo: 9265500},
  %{name: "Fraiha", imo: 9360817},
  %{name: "Lijmiliya", imo: 9388819},
  %{name: "Mesaimeer", imo: 9337729},
  %{name: "Milaha Ras Laffan", imo: 9255854},
  %{name: "Mozah", imo: 9337755},
  %{name: "Onaiza", imo: 9397353},
  %{name: "Rasheeda", imo: 9443413},
  %{name: "Shagra", imo: 9418365},
  %{name: "Tembek", imo: 9337731},
  %{name: "Umm Al Amad", imo: 9360829},
  %{name: "Umm Bab", imo: 9308431},
  %{name: "Umm Slal", imo: 9525857},
  %{name: "Zarga", imo: 9431214},
  %{name: "Zekreet", imo: 9132818}
]
|> Enum.map(fn(vessel) ->
  Repo.get_or_insert!(Vessel, vessel)
end)


[
  %{name: "MGO (DMA)"},
  %{name: "Gas Oil (Sul 0.10%)"},
  %{name: "RMG 380 - Sulphur max 3.50% (ISO 2005)"},
  %{name: "RMG 380 - Sulphur Max 3.50% (ISO 2010)"},
  %{name: "RMG 380 - Sulphur Max 3.50% (ISO 2012)"}
]
|> Enum.map(fn(fuel) ->
  Repo.get_or_insert!(Fuel, fuel)
end)


[fuel1, vessel1, port1] = [[%{name: "MGO (DMA)"}, Fuel],
  [%{name: "Boaty McBoatFace", imo: 1234567}, Vessel],
  [%{name: "Algeciras", country: "Spain", gmt_offset: 1}, Port]]
|> Enum.map(fn([data, module]) -> Repo.get_or_insert!(module, data) end)

Repo.get_or_insert!(Auction, %{vessel_id: vessel1.id, port_id: port1.id, fuel_id: fuel1.id, company: "Glencore", po: "1234567"})
