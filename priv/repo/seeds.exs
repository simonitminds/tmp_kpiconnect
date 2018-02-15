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
alias Oceanconnect.Accounts.{Company, User}
alias Oceanconnect.Auctions
alias Oceanconnect.Auctions.{Auction, Fuel, Port, Vessel}


companies = [
  %{name: "Global Energy Trading Pte Ltd", address1: "Alexandra Point",
    address2: "4438 Alexandra Road, #13-01", city: "Singapore",
    country: "Singapore", contact_name: "Munee Chow", email: "sales@genergytrading.com",
    main_phone: "+65 6559 1631", mobile_phone: "+65 9785 6238", postal_code: 11958},
  %{name: "Petrochina International (Singapore) Pte Ltd", address1: "One Temasek Avenue",
    address2: "#27-00 Millenia Tower", city: "Singapore",
    country: "Singapore", contact_name: "Wee Tee Ng", email: "ng-weetee@petrochina.com.sg",
    main_phone: "+65 6411 7513", mobile_phone: "+65 9119 0771", postal_code: 039192},
  %{name: "Shell International Eastern Trading Company", address1: "The Metropolis Tower",
    address2: "1-9 North Bueno Vista Drive", city: "Singapore",
    country: "Singapore", contact_name: "Benjamin Ong", email: "benjamin.ong@shell.com",
    main_phone: "+65 6505 2612", mobile_phone: "+65 9727 8577", postal_code: 138588},
  %{name: "Qatargas Operating Company Limited", address1: "Office 2W-705",
    address2: "", city: "Doha",
    country: "Qatar", contact_name: "Lee Pritchard", email: "lpritchard@qatargas.com.qa",
    main_phone: "+974 4452 3043", mobile_phone: "+44 7803 632226", postal_code: 22666},
]
|> Enum.map(fn(company) ->
  Repo.get_or_insert!(Company, company)
end)
[buyer_company | suppliers] = companies

# User creation doesn't use get_or_insert! fn due to virtual password field
Enum.map(companies, fn(c) ->
  if c.name == buyer_company.name do
    Repo.get_or_insert_user!(Repo.get_by(User, %{email: "test@example.com"}), "test@example.com", c)
  else
    Repo.get_or_insert_user!(Repo.get_by(User, %{email: c.email}), c.email, c)
  end
end)


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
  %{name: "Hercules Voyager", imo: 9583732, company_id: buyer_company.id},
  %{name: "LEO VOYAGER", imo: 9602473, company_id: buyer_company.id},
  %{name: "LIBRA VOYAGER", imo: 9593206, company_id: buyer_company.id},
  %{name: "Gaz Providence", imo: 9448504, company_id: buyer_company.id},
  %{name: "LNG Abalamabie", imo: 9690171, company_id: buyer_company.id},
  %{name: "LNG Adamawa ", imo: 9262211, company_id: buyer_company.id},
  %{name: "LNG Akwa Ibom", imo: 9262209, company_id: buyer_company.id},
  %{name: "LNG Bayelsa ", imo: 9241267, company_id: buyer_company.id},
  %{name: "LNG Borno", imo: 9322803, company_id: buyer_company.id},
  %{name: "LNG Cross River", imo: 9262223, company_id: buyer_company.id},
  %{name: "LNG Enugu", imo: 9266994, company_id: buyer_company.id},
  %{name: "LNG IMO", imo: 9311581, company_id: buyer_company.id},
  %{name: "LNG Kano", imo: 9311567, company_id: buyer_company.id},
  %{name: "LNG Lagos II ", imo: 9692014, company_id: buyer_company.id},
  %{name: "LNG Lokoja", imo: 9269960, company_id: buyer_company.id},
  %{name: "LNG Ogun", imo: 9322815, company_id: buyer_company.id},
  %{name: "LNG Ondo", imo: 9311579, company_id: buyer_company.id},
  %{name: "LNG Oyo", imo: 9267003, company_id: buyer_company.id},
  %{name: "Lng Port-Harcourt II", imo: 9690157, company_id: buyer_company.id},
  %{name: "LNG River Orashi", imo: 9266982, company_id: buyer_company.id},
  %{name: "LNG RIVERS", imo: 9216298, company_id: buyer_company.id},
  %{name: "LNG Sokoto", imo: 9216303, company_id: buyer_company.id},
  %{name: "Aamira", imo: 9443401, company_id: buyer_company.id},
  %{name: "Al Bahiya", imo: 9431147, company_id: buyer_company.id},
  %{name: "Al Bidda", imo: 9132741, company_id: buyer_company.id},
  %{name: "Al Dafna", imo: 9443683, company_id: buyer_company.id},
  %{name: "Al Gattara", imo: 9337705, company_id: buyer_company.id},
  %{name: "Al Ghariya", imo: 9337987, company_id: buyer_company.id},
  %{name: "Al Gharrafa", imo: 9337717, company_id: buyer_company.id},
  %{name: "Al Ghashamiya", imo: 9397286, company_id: buyer_company.id},
  %{name: "Al Hamla", imo: 9337743, company_id: buyer_company.id},
  %{name: "Al Huwaila", imo: 9360879, company_id: buyer_company.id},
  %{name: "Al Jasra", imo: 9132791, company_id: buyer_company.id},
  %{name: "Al Karaana", imo: 9431123, company_id: buyer_company.id},
  %{name: "Al Kharaitiyat", imo: 9397327, company_id: buyer_company.id},
  %{name: "Al Kharsaah", imo: 9360881, company_id: buyer_company.id},
  %{name: "Al Khattiya", imo: 9431111, company_id: buyer_company.id},
  %{name: "Al Khor", imo: 9085613, company_id: buyer_company.id},
  %{name: "Al Mafyar", imo: 9397315, company_id: buyer_company.id},
  %{name: "Al Nuaman", imo: 9431135, company_id: buyer_company.id},
  %{name: "Al Rayyan", imo: 9086734, company_id: buyer_company.id},
  %{name: "Al Rekayyat", imo: 9397339, company_id: buyer_company.id},
  %{name: "Al Ruwais", imo: 9337951, company_id: buyer_company.id},
  %{name: "Al Sadd", imo: 9397341, company_id: buyer_company.id},
  %{name: "Al Safliya", imo: 9337963, company_id: buyer_company.id},
  %{name: "Al Samriya", imo: 9388821, company_id: buyer_company.id},
  %{name: "Al Shamal", imo: 9360893, company_id: buyer_company.id},
  %{name: "Al Sheehaniya", imo: 9360831, company_id: buyer_company.id},
  %{name: "Al Wajbah", imo: 9085625, company_id: buyer_company.id},
  %{name: "Al Wakrah", imo: 9086746, company_id: buyer_company.id},
  %{name: "Al Zubarah", imo: 9085649, company_id: buyer_company.id},
  %{name: "Broog", imo: 9085651, company_id: buyer_company.id},
  %{name: "Bu Samra", imo: 9388833, company_id: buyer_company.id},
  %{name: "Doha", imo: 9085637, company_id: buyer_company.id},
  %{name: "Duhail", imo: 9337975, company_id: buyer_company.id},
  %{name: "Dukhan", imo: 9265500, company_id: buyer_company.id},
  %{name: "Fraiha", imo: 9360817, company_id: buyer_company.id},
  %{name: "Lijmiliya", imo: 9388819, company_id: buyer_company.id},
  %{name: "Mesaimeer", imo: 9337729, company_id: buyer_company.id},
  %{name: "Milaha Ras Laffan", imo: 9255854, company_id: buyer_company.id},
  %{name: "Mozah", imo: 9337755, company_id: buyer_company.id},
  %{name: "Onaiza", imo: 9397353, company_id: buyer_company.id},
  %{name: "Rasheeda", imo: 9443413, company_id: buyer_company.id},
  %{name: "Shagra", imo: 9418365, company_id: buyer_company.id},
  %{name: "Tembek", imo: 9337731, company_id: buyer_company.id},
  %{name: "Umm Al Amad", imo: 9360829, company_id: buyer_company.id},
  %{name: "Umm Bab", imo: 9308431, company_id: buyer_company.id},
  %{name: "Umm Slal", imo: 9525857, company_id: buyer_company.id},
  %{name: "Zarga", imo: 9431214, company_id: buyer_company.id},
  %{name: "Zekreet", imo: 9132818, company_id: buyer_company.id}
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
  [%{name: "Boaty McBoatFace", imo: 1234567, company_id: buyer_company.id}, Vessel],
  [%{name: "Algeciras", country: "Spain", gmt_offset: 1}, Port]]
|> Enum.map(fn([data, module]) -> Repo.get_or_insert!(module, data) end)

auction_params = %{
  vessel_id: vessel1.id,
  port_id: port1.id,
  fuel_id: fuel1.id,
  po: "1234567",
  buyer_id: buyer_company.id,
  duration: 1 * 60_000,
  decision_duration: 1 * 60_000
}

auction = Repo.get_or_insert!(Auction, auction_params)

Auctions.set_suppliers_for_auction(auction, suppliers)
Accounts.set_ports_on_company(buyer_company, Auctions.list_ports())
Accounts.set_vessels_on_company(buyer_company, Auctions.list_vessels())
