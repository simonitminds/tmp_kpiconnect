import React from 'react';
import _ from 'lodash';
import { formatTime } from '../../utilities';

const SupplierWinningBid = ({auction}) => {
  const fuel = _.get(auction, 'fuel.name');
  const bidList = _.get(auction, 'bid_list', []);
  const winningBid = _.get(auction, 'state.winning_bid');
  const order = _.get(auction, 'state.winning_bid_position');
  const bidStatsDisplay = () => {
    if(auction.state.status != "pending") {
      if (bidList.length == 0) {
        return (
          <div className = "auction-notification box is-warning" >
            <h3 className="has-text-weight-bold is-flex">
            <span className="is-inline-block qa-supplier-bid-status-message">You have not bid on this auction</span>
            </h3>
          </div>
        );
      }
      else if (order == 0) {
        return (
          <div className = "auction-notification box is-success" >
            <h3 className="has-text-weight-bold is-flex">
            <span className="is-inline-block qa-supplier-bid-status-message">Your bid is currently lowest</span>
            </h3>
          </div>
        );
      }
      else if (order > 0) {
        return (
          <div className = "auction-notification box is-success" >
            <h3 className="has-text-weight-bold is-flex">
            <span className="is-inline-block qa-supplier-bid-status-message">You are in lowest bid position number {order + 1}</span>
            </h3>
          </div>
        );
      }
      else {
        return (
          <div className = "auction-notification box is-danger" >
            <h3 className="has-text-weight-bold is-flex">
            <span className="is-inline-block qa-supplier-bid-status-message">You have been outbid</span>
            </h3>
          </div>
        );
      }
    }
  }

  const winningBidListDisplay = () => {
    if (_.get(winningBid, 'amount')) {
      return (
        <table className="table is-fullwidth is-striped is-marginless">
          <thead>
            <tr>
              <th>{fuel}</th>
              <th>Time</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td className="qa-auction-winning-bid-amount">${winningBid.amount}</td>
              <td>{formatTime(winningBid.time_entered)}</td>
            </tr>
          </tbody>
        </table>
      );
    } else {
      return <div className="auction-table-placeholder">
        <i>No bids have been placed on this auction</i>
      </div>;
    }
  }

  return(
    <div>
      {bidStatsDisplay()}
      <div className="box">
        <div className="box__subsection">
          <h3 className="box__header box__header--bordered">Winning Bid(s)</h3>
          {winningBidListDisplay()}
        </div>
      </div>
    </div>
  );
};
export default SupplierWinningBid;
