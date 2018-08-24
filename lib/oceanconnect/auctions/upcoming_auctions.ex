defmodule Oceanconnect.Auctions.UpcomingAuctions do
  use Task, restart: :permanent

  alias Oceanconnect.Auctions

  def start_link(polling_frequency, time_frame) do
    Task.start_link(__MODULE__, :poll, [polling_frequency, time_frame])
  end

  def poll(polling_frequency, time_frame) do
    receive do
    after
      polling_frequency ->
        upcoming_auctions = Auctions.list_upcoming_auctions(time_frame)
        for auction <- upcoming_auctions do
          case Auctions.upcoming_notification_sent?(auction) do
            true -> poll(polling_frequency, time_frame)
            false ->
              Auctions.notify_upcoming_auction(auction)
              poll(polling_frequency, time_frame)
          end
        end
    end
  end
end
