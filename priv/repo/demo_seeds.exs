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
  %{name: "Chevron Overseas Tankers", address1: "Shipping Operations",
    address2: "", city: "Singapore", is_supplier: false,
    country: "Singapore", contact_name: "Chevron Buyer", email: "chevron@example.com",
    main_phone: "+65 5555 5555", mobile_phone: "+65 5555 5555", postal_code: "555555"},
  %{name: "Korean Bunkers", address1: "Shipping Operations",
    address2: "", city: "Singapore", is_supplier: true,
    country: "Singapore", contact_name: "SI Shim", email: "si@example.com",
    main_phone: "+65 5555 5555", mobile_phone: "+65 5555 5555", postal_code: "555555"},
  %{name: "Susanna Services", address1: "Shipping Operations",
    address2: "", city: "Singapore", is_supplier: true,
    country: "Singapore", contact_name: "Oh Susanna", email: "susanna@example.com",
    main_phone: "+65 5555 5555", mobile_phone: "+65 5555 5555", postal_code: "555555"},
  %{name: "James’ Jumble Trading", address1: "Shipping Operations",
    address2: "", city: "Singapore", is_supplier: true,
    country: "Singapore", contact_name: "James Nash", email: "james@example.com",
    main_phone: "+65 5555 5555", mobile_phone: "+65 5555 5555", postal_code: "555555"},
  %{name: "Anthi’s Barge Chartering", address1: "Shipping Operations",
    address2: "#27-00 Millenia Tower", city: "Singapore", is_supplier: true,
    country: "Singapore", contact_name: "Anthi Barges", email: "anthi@example.com",
    main_phone: "+65 5555 5555", mobile_phone: "+65 5555 5555", postal_code: "555555"},
  %{name: "Blooming Rose Bunkers", address1: "Shipping Operations",
    address2: "4438 Alexandra Road, #13-01", city: "Singapore",
    country: "Singapore", contact_name: "Daniel Rose", email: "daniel@example.com",
    main_phone: "+65 5555 5555", mobile_phone: "+65 5555 5555", postal_code: "555555"},
  %{name: "Soon Joon Trading", address1: "Shipping Operations",
    address2: "", city: "Singapore", is_supplier: true,
    country: "Singapore", contact_name: "Joon Kim", email: "joon@example.com",
    main_phone: "+65 5555 5555", mobile_phone: "+65 5555 5555", postal_code: "555555"},
  %{name: "Foulger’s Fly by night Supply co.", address1: "Shipping Operations",
    address2: "", city: "Singapore", is_supplier: true,
    country: "Singapore", contact_name: "Grant Foulger", email: "grant@example.com",
    main_phone: "+65 5555 5555", mobile_phone: "+65 5555 5555", postal_code: "555555"},
  %{name: "Billly Bunkers ", address1: "Shipping Operations",
    address2: "", city: "Singapore", is_supplier: true,
    country: "Singapore", contact_name: "Bill Wakeling", email: "bill@example.com",
    main_phone: "+65 5555 5555", mobile_phone: "+65 5555 5555", postal_code: "555555"},
  %{name: "Flow Jo Trade and Transport", address1: "Shipping Operations",
    address2: "", city: "Singapore", is_supplier: true,
    country: "Singapore", contact_name: "Joanne Constantine", email: "joanne@example.com",
    main_phone: "+65 5555 5555", mobile_phone: "+65 5555 5555", postal_code: "555555"}
]
|> Enum.map(fn(company) ->
  Repo.get_or_insert!(Company, company)
end)
[buyer | suppliers] = companies

# User creation doesn't use get_or_insert! fn due to virtual password field
Enum.map(companies, fn(c) ->
  Repo.get_or_insert_user!(Repo.get_by(User, %{email: String.upcase(c.email)}), String.upcase(c.email), c)
end)

ports = [
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

vessels = [
  %{name: "Andromeda Voyager", imo: 9288875, company_id: buyer.id},
  %{name: "Hercules Voyager", imo: 9583732, company_id: buyer.id},
  %{name: "LEO VOYAGER", imo: 9602473, company_id: buyer.id},
  %{name: "LIBRA VOYAGER", imo: 9593206, company_id: buyer.id}
]
|> Enum.map(fn(vessel) ->
  Repo.get_or_insert!(Vessel, vessel)
end)

fuels = [
  %{name: "MGO (DMA)"},
  %{name: "Gas Oil (Sul 0.10%)"},
  %{name: "RMG 380 - Sulphur max 3.50% (ISO 2005)"},
  %{name: "RMG 380 - Sulphur Max 3.50% (ISO 2010)"},
  %{name: "RMG 380 - Sulphur Max 3.50% (ISO 2012)"}
]
|> Enum.map(fn(fuel) ->
  Repo.get_or_insert!(Fuel, fuel)
end)

[fuel1, vessel1, port1] = [[%{name: "RMG 380 - Sulphur max 3.50% (ISO 2005)"}, Fuel],
  [%{name: "Boaty McBoatFace", imo: 1234567, company_id: buyer.id}, Vessel],
  [%{name: "Singapore", country: "Singapore", gmt_offset: 8}, Port]]
|> Enum.map(fn([data, module]) -> Repo.get_or_insert!(module, data) end)

Accounts.set_ports_on_company(buyer, ports)
Enum.map(suppliers, fn(supplier) ->
  Accounts.add_port_to_company(supplier, port1)
end)


{:ok, date_time, _} = DateTime.from_iso8601("2018-05-21T12:00:00Z")
auctions_params = [
  %{
    vessel_id: vessel1.id,
    port_id: port1.id,
    fuel_id: fuel1.id,
    fuel_quantity: 1000,
    scheduled_start: date_time,
    eta: date_time,
    po: "1234567",
    buyer_id: buyer.id,
    duration: 5 * 60_000,
    decision_duration: 15 * 60_000
  },
  %{
    vessel_id: List.first(vessels).id,
    port_id: port1.id,
    fuel_id: List.first(fuels).id,
    fuel_quantity: 2000,
    scheduled_start: date_time,
    eta: date_time,
    po: "2345678",
    buyer_id: buyer.id,
    duration: 10 * 60_000,
    decision_duration: 15 * 60_000
  },
]

[auction1, auction2] = Enum.map(auctions_params, fn(auction_params) ->
  Repo.get_or_insert!(Auction, auction_params)
end)

defmodule SupplierHelper do
  def set_suppliers_for_auction(%Auction{} = auction, suppliers) when is_list(suppliers) do
    auction
    |> Repo.preload(:suppliers)
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:suppliers, suppliers)
    |> Repo.update!
    |> Auctions.create_supplier_aliases
  end
end

SupplierHelper.set_suppliers_for_auction(auction1, suppliers)
SupplierHelper.set_suppliers_for_auction(auction2, suppliers)
