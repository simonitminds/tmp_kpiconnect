import React from 'react';
import _ from 'lodash';
import { quickOrdinal } from '../../utilities';

const SupplierBidStatus = ({auction}) => {
  const bidList = _.get(auction, 'bid_list', []);
  const order = _.get(auction, 'state.winning_bids_position');

  if(auction.state.status != "pending") {
    if (bidList.length == 0) {
      return (
        <div className = "auction-notification box is-warning" >
          <h3 className="has-text-weight-bold is-flex">
          <span className="auction-notification__copy qa-supplier-bid-status-message">You have not bid on this auction</span>
          </h3>
        </div>
      );
    }
    else if (order == 0) {
      return (
        <div className = "auction-notification box is-success" >
          <h3 className="has-text-weight-bold is-flex">
          <span className="auction-notification__copy qa-supplier-bid-status-message">Your bid is currently lowest</span>
          </h3>
        </div>
      );
    }
    else if (order > 0) {
      return (
        <div className = "auction-notification box is-success" >
          <h3 className="has-text-weight-bold is-flex">
          <span className="auction-notification__copy qa-supplier-bid-status-message">Your bid is the lowest price ({order + 1}{quickOrdinal(order + 1)})</span>
          </h3>
        </div>
      );
    }
    else {
      return (
        <div className = "auction-notification box is-danger" >
          <h3 className="has-text-weight-bold is-flex">
          <span className="auction-notification__copy qa-supplier-bid-status-message">You have been outbid</span>
          </h3>
        </div>
      );
    }
  } else {
    return <i>The auction has not started</i>;
  }
};

export default SupplierBidStatus;
