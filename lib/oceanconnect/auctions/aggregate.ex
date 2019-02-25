defprotocol Oceanconnect.Auctions.Aggregate do
  alias Oceanconnect.Auctions.AuctionEventStore

  @doc "Validate the command's request and return a list of events representing
        the actions needed to complete the command."
  def process(state, command)

  @doc "Create a snapshot event to be persisted to the database manually."
  def snapshot(state, adapter \\ AuctionEventStore)

  @doc "Ammend `state` based on the given Event."
  def apply(state, event)
end
