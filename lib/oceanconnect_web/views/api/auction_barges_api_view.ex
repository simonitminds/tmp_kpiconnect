# defmodule OceanconnectWeb.Api.AuctionBargesView do
#   use OceanconnectWeb, :view

#   def render("index.json", %{data: data}) do
#     embedded_barges = Enum.map(company_barges, fn(barge) ->
#       %{barge | port: barge.port.name}
#     end)

#     %{data: embedded_barges}
#   end
# end
