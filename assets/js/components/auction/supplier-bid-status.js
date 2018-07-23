import React from 'react';
import _ from 'lodash';
import { quickOrdinal } from '../../utilities';

const SupplierBidStatus = ({auctionPayload, connection}) => {
  const bidList = _.get(auctionPayload, 'bid_history', []);
  const lowestBids = _.get(auctionPayload, 'lowest_bids');
  const auctionStatus = _.get(auctionPayload, 'status');
  const companyId = window.companyId;
  // TODO: calculate all based on `payload.lowest_bids`.
  const suppliersLowestBid = lowestBids.find((bid) => bid.supplier_id == companyId);
  const rank = lowestBids.indexOf(suppliersLowestBid);
  const matches_best = lowestBids.length > 0 && (lowestBids[0].amount == suppliersLowestBid.amount);
  const winner = rank == 0;

  const messageDisplay = (message) => {
    return (
      <h3 className="has-text-weight-bold">
        <span className="auction-notification__copy qa-supplier-bid-status-message">
          {message}
        </span>
      </h3>
    );
  }

  if(auctionStatus == "pending") {
    return <i>The auction has not started</i>;
  } else if (auctionStatus == "expired") {
    return (
      <div className = "auction-notification box is-gray-3" >
        {messageDisplay("No offer was selected")}
      </div>
    );
  } else if (auctionStatus == "closed" && winner) {
    return (
      <div className = "auction-notification box is-success" >
        {messageDisplay("You won the auction")}
      </div>
    );
  } else if (auctionStatus == "closed" && !winner) {
    return (
      <div className = "auction-notification box is-danger" >
        {messageDisplay("You lost the auction")}
      </div>
    );
  } else if (auctionStatus == "open" && !connection) {
    return (
      <div className = "auction-notification box is-gray-2" >
        {messageDisplay("Your connection to the server has been lost")}
      </div>
    )
  } else if (bidList.length == 0) {
    return (
      <div className = "auction-notification box is-warning" >
        {messageDisplay("You have not bid on this auction")}
      </div>
    );
  } else if (matches_best && rank != null) {
    return (
      <div className = "auction-notification box is-success" >
        {messageDisplay(`Your bid matches the best offer (${rank + 1}${quickOrdinal(rank + 1)})`)}
      </div>
    );
  } else if (rank == 0) {
    return (
      <div className = "auction-notification box is-success" >
        {messageDisplay("Your bid is the best offer")}
      </div>
    );
  } else {
    return (
      <div className = "auction-notification box is-danger" >
        {messageDisplay("Your bid is not the best offer")}
      </div>
    );
  }
};

export default SupplierBidStatus;
