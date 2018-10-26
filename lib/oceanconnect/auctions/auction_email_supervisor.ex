defmodule Oceanconnect.Auctions.AuctionEmailSupervisor do
  use Supervisor

  alias Oceanconnect.Auctions.{
    Auction,
    AuctionEmailNotificationHandler
  }

  @registry_name :auction_email_supervisor_registry

  def start_link({auction = %Auction{id: auction_id}, config}) do
    Supervisor.start_link(
      __MODULE__,
      {auction, config},
      name: get_auction_email_supervisor_name(auction_id)
    )
  end

  def init({%Auction{id: auction_id}, _options}) do
    children = [
      {AuctionEmailNotificationHandler, auction_id}
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end

  defp get_auction_email_supervisor_name(auction_id) do
    {:via, Registry, {@registry_name, auction_id}}
  end

  def find_pid(auction_id) do
    with [{pid, _}] <- Registry.lookup(@registry_name, auction_id) do
      {:ok, pid}
    else
      [] -> {:error, "Auction Email Supervisor Not Started"}
    end
  end

  defp exclude_children(children, %{exclude_children: exclusions}) do
    children_included =
      children
      |> Enum.reject(fn {k, _v} -> k in exclusions end)
      |> Enum.map(fn {_, v} -> v end)

    children_included
  end

  defp exclude_children(children, %{}), do: children |> Map.values()
end
