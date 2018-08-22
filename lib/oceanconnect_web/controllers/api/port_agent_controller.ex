defmodule OceanconnectWeb.Api.PortAgentController do
  use OceanconnectWeb, :controller
  alias Oceanconnect.Auctions

  def update(conn, %{"auction_id" => auction_id, "port_agent" => port_agent}) do
    updated_port_agent = nilify_blank(port_agent)
    buyer = OceanconnectWeb.Plugs.Auth.current_user(conn)

    with auction = %Auctions.Auction{} <- Auctions.get_auction(auction_id),
         true <- buyer.company_id == auction.buyer_id,
         {:ok, _} <- maybe_update_port_agent(auction, updated_port_agent, buyer) do
      render(conn, "show.json", data: %{})
    else
      _ ->
        conn
        |> put_status(422)
        |> render(OceanconnectWeb.ErrorView, "422.json", data: %{})
    end
  end

  defp maybe_update_port_agent(%{port_agent: port_agent}, port_agent, _buyer), do: {:ok, nil}

  defp maybe_update_port_agent(auction, port_agent, buyer) do
    Auctions.update_auction(auction, %{port_agent: port_agent}, buyer)
  end

  defp nilify_blank(""), do: nil
  defp nilify_blank(port_agent), do: port_agent
end
