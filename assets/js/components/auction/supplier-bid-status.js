import React from 'react';
import _ from 'lodash';
import { quickOrdinal } from '../../utilities';

const SupplierBidStatus = ({auctionPayload, connection}) => {
  const bidList = _.get(auctionPayload, 'bid_history', []);
  const lowestBids = _.get(auctionPayload, 'lowest_bids');
  const auctionStatus = _.get(auctionPayload, 'status');
  const companyId = window.companyId;
  // const suppliersLowestBid = lowestBids.find((bid) => bid.supplier_id == companyId);
  // const rank = lowestBids.indexOf(suppliersLowestBid);
  const isLeading = _.get(auctionPayload, 'is_leading');
  const leadIsTied = _.get(auctionPayload, 'lead_is_tied');
  const winning_bid = _.get(auctionPayload, 'winning_bid')
  const winner = winning_bid && winning_bid.supplier_id == companyId;

  const messageDisplay = (message) => {
    return (
      <h3 className="has-text-weight-bold has-margin-bottom-none">
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
        <div className="auction-notification__show-message">
          {messageDisplay("Regretfully, you were unsuccessful in this auction. Thank you for quoting")}
        </div>
        <div className="auction-notification__card-message">
          {messageDisplay("You lost the auction")}
        </div>
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
  } else if (isLeading && leadIsTied) {
    return (
      <div className = "auction-notification box is-success" >
        {messageDisplay(`Your bid matches the best offer (${rank + 1}${quickOrdinal(rank + 1)})`)}
      </div>
    );
  } else if (isLeading) {
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
