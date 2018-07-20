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

alias Oceanconnect.Auctions.{
  Auction,
  AuctionEvent,
  AuctionEventStorage,
  Barge,
  Fuel,
  Port,
  Vessel
}

defmodule SupplierHelper do
  def set_suppliers_for_auction(%Auction{} = auction, suppliers) when is_list(suppliers) do
    auction
    |> Repo.preload(:suppliers)
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:suppliers, suppliers)
    |> Repo.update!()
    |> Auctions.create_supplier_aliases()
  end

  def british_date_string_to_naive_date_time(string) do
    [day, month, year] =
      string
      |> String.split("/")
      |> Enum.map(&String.to_integer(&1))

    {:ok, date} = NaiveDateTime.new(year, month, day, 0, 0, 0)
    date
  end
end

companies =
  [
    %{
      name: "Chevron Overseas Tankers",
      address1: "1 Westferry Circus",
      address2: "Canary Wharf",
      city: "London",
      is_supplier: false,
      country: "UK",
      contact_name: "Rob Ferry",
      email: "chevron@example.com",
      main_phone: "+442077193000",
      mobile_phone: "+44 7920 231948",
      postal_code: "E14 4HA"
    },
    %{
      name: "Nigeria LNG",
      address1: "Shipping Operations",
      address2: "",
      city: "Lagos",
      is_supplier: false,
      country: "Nigeria",
      contact_name: "Nnamse Sundasen",
      email: "nigeria@example.com",
      main_phone: "+234 1 2611275",
      mobile_phone: "+234 80 3938 0297",
      postal_code: ""
    },
    %{
      name: "Qatargas Operating Company Limited",
      address1: "28th Floor",
      address2: "Palm Tower",
      city: "Doha",
      is_supplier: true,
      country: "Qatar",
      contact_name: "Lee Pritchard",
      email: "qatargas@example.com",
      main_phone: "+974 4452 3043",
      mobile_phone: "+44 7803 632226",
      postal_code: "22666"
    },
    %{
      name: "Petrochina International (Singapore) Pte Ltd",
      address1: "One Temasek Avenue",
      address2: "#27-00 Millenia Tower",
      city: "Singapore",
      is_supplier: true,
      country: "Singapore",
      contact_name: "Wee-Tee Ng",
      email: "petrochina@example.com",
      main_phone: "+65 6411 7513",
      mobile_phone: "+65 9119 0771",
      postal_code: "039192"
    },
    %{
      name: "Global Energy Trading Pte Ltd",
      address1: "Alexandra Point",
      address2: "4438 Alexandra Road, #13-01",
      city: "Singapore",
      country: "Singapore",
      contact_name: "Munee Chow",
      email: "genergytrading@example.com",
      main_phone: "+65 6559 1631",
      mobile_phone: "+65 9785 6238",
      postal_code: "11958"
    },
    %{
      name: "Shell International Eastern Trading Company",
      address1: "The Metropolis Tower",
      address2: "1-9 North Bueno Vista Drive",
      city: "Singapore",
      is_supplier: true,
      country: "Singapore",
      contact_name: "Benjamin Ong",
      email: "shell@example.com",
      main_phone: "+65 6505 2612",
      mobile_phone: "+65 9727 8577",
      postal_code: "138588"
    },
    %{
      name: "Chemoil Internatinoal Pte Ltd",
      address1: "1 Temasek Avenue",
      address2: "#34-01 Mellenia Tower",
      city: "Singapore",
      is_supplier: true,
      country: "Singapore",
      contact_name: "Hwee-Cheng Chua",
      email: "chemoil@example.com",
      main_phone: "+65 6415 7653",
      mobile_phone: "+65 9672 1065",
      postal_code: "039192"
    }
  ]
  |> Enum.map(fn company ->
    Repo.get_or_insert!(Company, company)
  end)

[chevron, nigeria, qatargas, petrochina, global, shell, chemoil] = companies
suppliers = companies
# User creation doesn't use get_or_insert! fn due to virtual password field
Enum.map(companies, fn c ->
  Repo.get_or_insert_user!(
    Repo.get_by(User, %{email: String.upcase(c.email)}),
    String.upcase(c.email),
    c
  )
end)

ports =
  [
    %{name: "Algeciras", country: "Spain", gmt_offset: 1},
    %{name: "Balboa", country: "Panama", gmt_offset: -5},
    %{name: "Cristobal", country: "Panama", gmt_offset: -5},
    %{name: "Dubai", country: "United Arab Emirates", gmt_offset: 4},
    %{name: "Fujairah", country: "United Arab Emirates", gmt_offset: 4},
    %{name: "Gibraltar", country: "Gibraltar", gmt_offset: 1},
    %{name: "Hong Kong", country: "China", gmt_offset: 8},
    %{name: "Khor Fakkan", country: "United Arab Emirates", gmt_offset: 4},
    %{name: "Las Palmas", country: "Spain", gmt_offset: 0},
    %{name: "Port Elizabeth", country: "South Africa", gmt_offset: 2},
    %{name: "Port Gentil", country: "Gabon", gmt_offset: 1},
    %{name: "Port Louis", country: "Mauritius", gmt_offset: 4},
    %{name: "Santa Cruz de Tenerife", country: "Spain", gmt_offset: 0},
    %{name: "Singapore", country: "Singapore", gmt_offset: 8},
    %{name: "Skaw", country: "Denmark", gmt_offset: 1}
  ]
  |> Enum.map(fn port ->
    Repo.get_or_insert!(Port, port)
  end)

[
  algeciras,
  balboa,
  christobal,
  dubai,
  fujairah,
  gibraltar,
  hong_kong,
  khor_fakkan,
  las_palmas,
  port_elizabeth,
  port_gentil,
  port_louis,
  santa_cruz,
  singapore,
  skaw
] = ports

vessels =
  [
    %{name: "Andromeda Voyager", imo: 9_288_875, company_id: chevron.id},
    %{name: "Hercules Voyager", imo: 9_583_732, company_id: chevron.id},
    %{name: "LEO VOYAGER", imo: 9_602_473, company_id: chevron.id},
    %{name: "LIBRA VOYAGER", imo: 9_593_206, company_id: chevron.id},
    %{name: "Gaz Providence", imo: 9_448_504, company_id: nigeria.id},
    %{name: "LNG Abalamabie", imo: 9_690_171, company_id: nigeria.id},
    %{name: "LNG Adamawa ", imo: 9_262_211, company_id: nigeria.id},
    %{name: "LNG Akwa Ibom", imo: 9_262_209, company_id: nigeria.id},
    %{name: "LNG Bayelsa ", imo: 9_241_267, company_id: nigeria.id},
    %{name: "LNG Borno", imo: 9_322_803, company_id: nigeria.id},
    %{name: "LNG Cross River", imo: 9_262_223, company_id: nigeria.id},
    %{name: "LNG Enugu", imo: 9_266_994, company_id: nigeria.id},
    %{name: "LNG IMO", imo: 9_311_581, company_id: nigeria.id},
    %{name: "LNG Kano", imo: 9_311_567, company_id: nigeria.id},
    %{name: "LNG Lagos II ", imo: 9_692_014, company_id: nigeria.id},
    %{name: "LNG Lokoja", imo: 9_269_960, company_id: nigeria.id},
    %{name: "LNG Ogun", imo: 9_322_815, company_id: nigeria.id},
    %{name: "LNG Ondo", imo: 9_311_579, company_id: nigeria.id},
    %{name: "LNG Oyo", imo: 9_267_003, company_id: nigeria.id},
    %{name: "Lng Port-Harcourt II", imo: 9_690_157, company_id: nigeria.id},
    %{name: "LNG River Orashi", imo: 9_266_982, company_id: nigeria.id},
    %{name: "LNG RIVERS", imo: 9_216_298, company_id: nigeria.id},
    %{name: "LNG Sokoto", imo: 9_216_303, company_id: nigeria.id},
    %{name: "Aamira", imo: 9_443_401, company_id: qatargas.id},
    %{name: "Al Bahiya", imo: 9_431_147, company_id: qatargas.id},
    %{name: "Al Bidda", imo: 9_132_741, company_id: qatargas.id},
    %{name: "Al Dafna", imo: 9_443_683, company_id: qatargas.id},
    %{name: "Al Gattara", imo: 9_337_705, company_id: qatargas.id},
    %{name: "Al Ghariya", imo: 9_337_987, company_id: qatargas.id},
    %{name: "Al Gharrafa", imo: 9_337_717, company_id: qatargas.id},
    %{name: "Al Ghashamiya", imo: 9_397_286, company_id: qatargas.id},
    %{name: "Al Hamla", imo: 9_337_743, company_id: qatargas.id},
    %{name: "Al Huwaila", imo: 9_360_879, company_id: qatargas.id},
    %{name: "Al Jasra", imo: 9_132_791, company_id: qatargas.id},
    %{name: "Al Karaana", imo: 9_431_123, company_id: qatargas.id},
    %{name: "Al Kharaitiyat", imo: 9_397_327, company_id: qatargas.id},
    %{name: "Al Kharsaah", imo: 9_360_881, company_id: qatargas.id},
    %{name: "Al Khattiya", imo: 9_431_111, company_id: qatargas.id},
    %{name: "Al Khor", imo: 9_085_613, company_id: qatargas.id},
    %{name: "Al Mafyar", imo: 9_397_315, company_id: qatargas.id},
    %{name: "Al Nuaman", imo: 9_431_135, company_id: qatargas.id},
    %{name: "Al Rayyan", imo: 9_086_734, company_id: qatargas.id},
    %{name: "Al Rekayyat", imo: 9_397_339, company_id: qatargas.id},
    %{name: "Al Ruwais", imo: 9_337_951, company_id: qatargas.id},
    %{name: "Al Sadd", imo: 9_397_341, company_id: qatargas.id},
    %{name: "Al Safliya", imo: 9_337_963, company_id: qatargas.id},
    %{name: "Al Samriya", imo: 9_388_821, company_id: qatargas.id},
    %{name: "Al Shamal", imo: 9_360_893, company_id: qatargas.id},
    %{name: "Al Sheehaniya", imo: 9_360_831, company_id: qatargas.id},
    %{name: "Al Wajbah", imo: 9_085_625, company_id: qatargas.id},
    %{name: "Al Wakrah", imo: 9_086_746, company_id: qatargas.id},
    %{name: "Al Zubarah", imo: 9_085_649, company_id: qatargas.id},
    %{name: "Broog", imo: 9_085_651, company_id: qatargas.id},
    %{name: "Bu Samra", imo: 9_388_833, company_id: qatargas.id},
    %{name: "Doha", imo: 9_085_637, company_id: qatargas.id},
    %{name: "Duhail", imo: 9_337_975, company_id: qatargas.id},
    %{name: "Dukhan", imo: 9_265_500, company_id: qatargas.id},
    %{name: "Fraiha", imo: 9_360_817, company_id: qatargas.id},
    %{name: "Lijmiliya", imo: 9_388_819, company_id: qatargas.id},
    %{name: "Mesaimeer", imo: 9_337_729, company_id: qatargas.id},
    %{name: "Milaha Ras Laffan", imo: 9_255_854, company_id: qatargas.id},
    %{name: "Mozah", imo: 9_337_755, company_id: qatargas.id},
    %{name: "Onaiza", imo: 9_397_353, company_id: qatargas.id},
    %{name: "Rasheeda", imo: 9_443_413, company_id: qatargas.id},
    %{name: "Shagra", imo: 9_418_365, company_id: qatargas.id},
    %{name: "Tembek", imo: 9_337_731, company_id: qatargas.id},
    %{name: "Umm Al Amad", imo: 9_360_829, company_id: qatargas.id},
    %{name: "Umm Bab", imo: 9_308_431, company_id: qatargas.id},
    %{name: "Umm Slal", imo: 9_525_857, company_id: qatargas.id},
    %{name: "Zarga", imo: 9_431_214, company_id: qatargas.id},
    %{name: "Zekreet", imo: 9_132_818, company_id: qatargas.id}
  ]
  |> Enum.map(fn vessel ->
    Repo.get_or_insert!(Vessel, vessel)
  end)

barges =
  [
    %{
      companies: [global],
      dwt: "2962",
      imo_number: "9515163",
      name: "ALPHA",
      port_id: singapore.id,
      sire_inspection_date: "3/4/18",
      sire_inspection_validity: true
    },
    %{
      companies: [chemoil],
      dwt: "6510",
      imo_number: "9571117",
      name: "AQUA 6",
      port_id: singapore.id,
      sire_inspection_date: "11/4/18",
      sire_inspection_validity: true
    },
    %{
      companies: [chemoil],
      dwt: "6510",
      imo_number: "9648790",
      name: "AQUA TERRA 7",
      port_id: singapore.id,
      sire_inspection_date: "12/4/18",
      sire_inspection_validity: true
    },
    %{
      companies: [global],
      dwt: "7376",
      imo_number: "9430612",
      name: "AVON",
      port_id: singapore.id,
      sire_inspection_date: "27/11/2017",
      sire_inspection_validity: true
    },
    %{
      companies: [global],
      dwt: "70343",
      imo_number: "9661443",
      name: "BRIGHTOIL 639",
      port_id: singapore.id,
      sire_inspection_date: "30/04/2017",
      sire_inspection_validity: false
    },
    %{
      companies: [global],
      dwt: "3861",
      imo_number: "394307",
      name: "COMO",
      port_id: singapore.id,
      sire_inspection_date: "20/06/2017",
      sire_inspection_validity: true
    },
    %{
      companies: [global],
      dwt: "4200",
      imo_number: "9680267",
      name: "CONGO",
      port_id: singapore.id,
      sire_inspection_date: "27/09/2017",
      sire_inspection_validity: true
    },
    %{
      companies: [global],
      dwt: "4459",
      imo_number: "9730191",
      name: "DESNA",
      port_id: singapore.id,
      sire_inspection_date: "30/01/2018",
      sire_inspection_validity: true
    },
    %{
      companies: [shell],
      dwt: "9480",
      imo_number: "9378694",
      name: "EAGER",
      port_id: singapore.id,
      sire_inspection_date: "28/07/2017",
      sire_inspection_validity: true
    },
    %{
      companies: [shell],
      dwt: "6284",
      imo_number: "9603659",
      name: "EMISSARY",
      port_id: singapore.id,
      sire_inspection_date: "25/08/2017",
      sire_inspection_validity: true
    },
    %{
      companies: [petrochina],
      dwt: "7285",
      imo_number: "9437971",
      name: "FELLOWSHIP",
      port_id: singapore.id,
      sire_inspection_date: "2/1/18",
      sire_inspection_validity: true
    },
    %{
      companies: [petrochina],
      dwt: "7000",
      imo_number: "9515424",
      name: "FLAGSHIP",
      port_id: singapore.id,
      sire_inspection_date: "20/12/2017",
      sire_inspection_validity: true
    },
    %{
      companies: [global],
      dwt: "4476",
      imo_number: "9680279",
      name: "HUMBER",
      port_id: singapore.id,
      sire_inspection_date: "18/12/2017",
      sire_inspection_validity: true
    },
    %{
      companies: [shell],
      dwt: "8679",
      imo_number: "9462081",
      name: "ISSELIA",
      port_id: singapore.id,
      sire_inspection_date: "27/10/2017",
      sire_inspection_validity: true
    },
    %{
      companies: [petrochina],
      dwt: "4708",
      imo_number: "9655389",
      name: "MARINE NOEL",
      port_id: singapore.id,
      sire_inspection_date: "31/08/2017",
      sire_inspection_validity: true
    },
    %{
      companies: [petrochina],
      dwt: "4708",
      imo_number: "9655391",
      name: "MARINE ORACLE",
      port_id: singapore.id,
      sire_inspection_date: "7/10/17",
      sire_inspection_validity: true
    },
    %{
      companies: [petrochina],
      dwt: "649400",
      imo_number: "9812676",
      name: "MARINE ROSE",
      port_id: singapore.id,
      sire_inspection_date: "12/10/17",
      sire_inspection_validity: true
    },
    %{
      companies: [petrochina],
      dwt: "653300",
      imo_number: "9813412",
      name: "MARINE SELENA",
      port_id: singapore.id,
      sire_inspection_date: "4/1/18",
      sire_inspection_validity: true
    },
    %{
      companies: [global],
      dwt: "1121",
      imo_number: "9817664",
      name: "MARINE UNIQUE",
      port_id: singapore.id,
      sire_inspection_date: "24/01/2018",
      sire_inspection_validity: true
    },
    %{
      companies: [petrochina],
      dwt: "5684",
      imo_number: "9639385",
      name: "NEPAMORA",
      port_id: singapore.id,
      sire_inspection_date: "20/03/2018",
      sire_inspection_validity: true
    },
    %{
      companies: [global],
      dwt: "7376",
      imo_number: "9434242",
      name: "OIGAWA",
      port_id: singapore.id,
      sire_inspection_date: "27/09/2017",
      sire_inspection_validity: true
    },
    %{
      companies: [chemoil],
      dwt: "6942",
      imo_number: "9384071",
      name: "PACIFIC FAITH",
      port_id: singapore.id,
      sire_inspection_date: "9/4/18",
      sire_inspection_validity: true
    },
    %{
      companies: [chemoil],
      dwt: "6941",
      imo_number: "9384083",
      name: "PACIFIC SPIRIT",
      port_id: singapore.id,
      sire_inspection_date: "25/08/2017",
      sire_inspection_validity: true
    },
    %{
      companies: [global],
      dwt: "7440",
      imo_number: "9503689",
      name: "PERL",
      port_id: singapore.id,
      sire_inspection_date: "5/7/17",
      sire_inspection_validity: true
    },
    %{
      companies: [petrochina],
      dwt: "4791",
      imo_number: "9662708",
      name: "PETRO ASIA",
      port_id: singapore.id,
      sire_inspection_date: "6/6/17",
      sire_inspection_validity: true
    },
    %{
      companies: [global],
      dwt: "1303",
      imo_number: "9677480",
      name: "SEA TANKER",
      port_id: singapore.id,
      sire_inspection_date: "24/11/2017",
      sire_inspection_validity: true
    },
    %{
      companies: [shell],
      dwt: "4700",
      imo_number: "9397767",
      name: "ZEMIRA",
      port_id: singapore.id,
      sire_inspection_date: "26/09/2017",
      sire_inspection_validity: true
    }
  ]
  |> Enum.map(fn barge ->
    %{
      barge
      | sire_inspection_date:
          SupplierHelper.british_date_string_to_naive_date_time(barge.sire_inspection_date)
    }
  end)
  |> Enum.map(fn barge_attrs ->
    data = Repo.get_or_insert!(Barge, Map.delete(barge_attrs, :companies))
    |> Repo.preload(:companies)

    Barge.changeset(data, barge_attrs)
    |> Ecto.Changeset.put_assoc(:companies, MapSet.new(barge_attrs.companies ++ data.companies) |> MapSet.to_list())
    |> Repo.update()
  end)

fuels =
  [
    %{name: "MGO (DMA)"},
    %{name: "Gas Oil (Sul 0.10%)"},
    %{name: "RMG 380 - Sulphur max 3.50% (ISO 2005)"},
    %{name: "RMG 380 - Sulphur Max 3.50% (ISO 2010)"},
    %{name: "RMG 380 - Sulphur Max 3.50% (ISO 2012)"}
  ]
  |> Enum.map(fn fuel ->
    Repo.get_or_insert!(Fuel, fuel)
  end)

[fuel1, vessel1, port1] =
  [
    [%{name: "RMG 380 - Sulphur max 3.50% (ISO 2005)"}, Fuel],
    [%{name: "Boaty McBoatFace", imo: 1_234_567, company_id: nigeria.id}, Vessel],
    [%{name: "Singapore", country: "Singapore", gmt_offset: 8}, Port]
  ]
  |> Enum.map(fn [data, module] -> Repo.get_or_insert!(module, data) end)

fujairah = Repo.get_by(Port, name: "Fujairah")

date_time =
  DateTime.utc_now()
  |> DateTime.to_naive()
  |> NaiveDateTime.add(3_600 * 24 * 30)
  |> DateTime.from_naive!("Etc/UTC")

auctions_params = [
  %{
    vessel_id: vessel1.id,
    port_id: port1.id,
    fuel_id: fuel1.id,
    fuel_quantity: 1000,
    scheduled_start: date_time,
    eta: date_time,
    po: "1234567",
    buyer_id: nigeria.id,
    duration: 1 * 60_000,
    decision_duration: 1 * 60_000
  },
  %{
    vessel_id: List.first(vessels).id,
    port_id: fujairah.id,
    fuel_id: List.first(fuels).id,
    fuel_quantity: 1000,
    scheduled_start: date_time,
    eta: date_time,
    po: "2345678",
    buyer_id: chevron.id,
    duration: 4 * 60_000,
    decision_duration: 4 * 60_000
  },
  %{
    vessel_id: List.last(vessels).id,
    port_id: port1.id,
    fuel_id: List.last(fuels).id,
    fuel_quantity: 1000,
    scheduled_start: date_time,
    eta: date_time,
    po: "3456789",
    buyer_id: qatargas.id,
    duration: 10 * 60_000,
    decision_duration: 15 * 60_000
  }
]

Enum.map([chevron, nigeria, qatargas], fn buyer ->
  Accounts.set_ports_on_company(buyer, ports)
end)

petrochina = hd(suppliers)
Accounts.add_port_to_company(petrochina, fujairah)
Accounts.add_port_to_company(petrochina, Repo.get_by(Port, name: "Khor Fakkan"))

Enum.map(suppliers, fn supplier ->
  Accounts.add_port_to_company(supplier, port1)
end)

[auction1, auction2, auction3] =
  Enum.map(auctions_params, fn auction_params ->
    Repo.get_or_insert!(Auction, auction_params)
  end)

[auction1, auction2, auction3]
|> Enum.map(fn auction ->
  event = AuctionEvent.auction_created(auction, nil)
  event_storage = %AuctionEventStorage{event: event, auction_id: auction.id}
  AuctionEventStorage.persist(event_storage)
end)

SupplierHelper.set_suppliers_for_auction(auction1, suppliers)
SupplierHelper.set_suppliers_for_auction(auction2, [petrochina])
SupplierHelper.set_suppliers_for_auction(auction3, suppliers)
