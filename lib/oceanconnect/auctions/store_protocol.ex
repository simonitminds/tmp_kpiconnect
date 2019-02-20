defprotocol Oceanconnect.Auctions.StoreProtocol do
  @doc "Determines whether this is the suppliers first bid based on the auction state"
  def is_suppliers_first_bid?(state, bid)

  @doc "Determines if the bid is the lowest bid"
  def is_lowest_bid?(state, bid)

  @doc "Starts the auction"
  def start_auction(state, auction, user, emit)

  @doc "Updates the auction"
  def update_auction(state, auction, emit)

  @doc "Updates the product bid state"
  def update_product_bid_state(state, auction)

  @doc "Cancel an auction"
  def cancel_auction(state, auction)

  @doc "Ends the auction"
  def end_auction(state, auction)

  @doc "Expire an auction"
  def expire_auction(state, auction)

  @doc "Processes a bid"
  def process_bid(state, bid)

  @doc "Revokes a supplier's bids"
  def revoke_supplier_bids(state, product_id, supplier_id)

  @doc "Select a winning solution"
  def select_winning_solution(state, solution, port_agent, auction)

  @doc "Submit a comment"
  def submit_comment(state, comment)

  @doc "Unsubmit a comment"
  def unsubmit_comment(state, comment)

  @doc "Submit an auction barge"
  def submit_barge(state, barge)

  @doc "Unsubmit an auction barge"
  def unsubmit_barge(state, barge)

  @doc "Approve an auction barge"
  def approve_barge(state, barge)

  @doc "Reject an auction barge"
  def reject_barge(state, barge)
end
