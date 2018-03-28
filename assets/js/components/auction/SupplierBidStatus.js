import React from 'react';
import _ from 'lodash';
import { quickOrdinal } from '../../utilities';

const SupplierBidStatus = ({auctionPayload}) => {
  const bidList = _.get(auctionPayload, 'bid_list', []);
  const order = _.get(auctionPayload, 'state.lowest_bids_position');
  const multiple = _.get(auctionPayload, 'state.multiple');
  const auctionStatus = _.get(auctionPayload, 'state.status');
  const winner = _.get(auctionPayload, 'state.winner');

  const messageDisplay = (message) => {
    return (
      <h3 className="has-text-weight-bold is-flex">
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
        {messageDisplay("The auction has expired with no offer selected")}
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
  } else if (bidList.length == 0) {
    return (
      <div className = "auction-notification box is-warning" >
        {messageDisplay("You have not bid on this auction")}
      </div>
    );
  } else if (order == 0 && !multiple) {
    return (
      <div className = "auction-notification box is-success" >
        {messageDisplay("Your bid is the best offer")}
      </div>
    );
  } else if (order >= 0 && order != null) {
    return (
      <div className = "auction-notification box is-success" >
        {messageDisplay(`Your bid matches the best offer (${order + 1}${quickOrdinal(order + 1)})`)}
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
