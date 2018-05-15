defmodule OceanconnectWeb.Api.PortAgentController do
  use OceanconnectWeb, :controller
  alias Oceanconnect.Auctions

  def update(conn, %{"auction_id" => auction_id, "port_agent" => port_agent}) do
    updated_port_agent = nilify_blank(port_agent)
    buyer_id = OceanconnectWeb.Plugs.Auth.current_user(conn).company_id
    with auction = %Auctions.Auction{} <- Auctions.get_auction(auction_id),
         true     <- buyer_id == auction.buyer_id,
         {:ok, _} <- maybe_update_port_agent(auction, updated_port_agent, buyer_id)
    do
      render(conn, "show.json", data: %{})
    else
      _ ->
        conn
        |> put_status(422)
        |> render(OceanconnectWeb.ErrorView, "422.json", data: %{})
    end
  end

  defp maybe_update_port_agent(%{port_agent: port_agent}, port_agent, _buyer_id), do: {:ok, nil}
  defp maybe_update_port_agent(auction, port_agent, buyer_id) do
    Auctions.update_auction(auction, %{port_agent: port_agent}, buyer_id)
  end

  defp nilify_blank(""), do: nil
  defp nilify_blank(port_agent), do: port_agent
end
