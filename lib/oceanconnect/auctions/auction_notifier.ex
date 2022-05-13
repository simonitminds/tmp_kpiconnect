defmodule Oceanconnect.Auctions.AuctionNotifier do
  import Oceanconnect.Auctions.Guards

  alias Oceanconnect.Accounts
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.AuctionPayload

  def notify_participants(state = %state_struct{auction_id: auction_id})
      when is_auction_state(state_struct) do
    auction_id
    |> Auctions.get_auction!()
    |> notify_participants(state)
  end

  def notify_participants(auction = %struct{}) when is_auction(struct) do
    auction_state = Auctions.get_auction_state!(auction)
    notify_participants(auction, auction_state)
  end

  def notify_participants(auction = %struct{}, state = %state_struct{})
      when is_auction_state(state_struct) and is_auction(struct) do
    companies =
      auction
      |> Auctions.auction_participant_ids()
      |> MapSet.new()
      |> MapSet.union(admins_and_observers(auction))
      |> MapSet.to_list()

    notify_auction_users(auction, companies, state)
  end

  def remove_observer(%struct{id: auction_id}, observer_id) when is_auction(struct) do
    OceanconnectWeb.Endpoint.broadcast!(
      "user_auctions:#{observer_id}",
      "remove_auction",
      %{id: auction_id}
    )
  end

  def send_notification_to_participant(channel, payload, participant_id) do
    OceanconnectWeb.Endpoint.broadcast!(
      "#{channel}:#{participant_id}",
      "auctions_update",
      payload
    )
  end

  defp admins_and_observers(auction) do
    Accounts.list_admin_users()
    |> Enum.map(& &1.company_id)
    |> MapSet.new()
    |> MapSet.union(MapSet.new(Auctions.auction_observer_ids(auction)))
  end

  defp notify_auction_users(auction, companies, state) do
    Enum.map(companies, fn company_id ->
      payload = AuctionPayload.get_auction_payload!(auction, company_id, state)
      send_notification_to_participant("user_auctions", payload, company_id)
    end)
  end
end
