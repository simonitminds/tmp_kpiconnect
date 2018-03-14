import React from 'react';
import _ from 'lodash';
import { formatTime } from '../../utilities';

const SupplierWinningBid = ({auction}) => {
  const fuel = _.get(auction, 'fuel.name');
  const bidList = _.get(auction, 'bidList', []);
  const winningBidList = _.get(auction, 'state.winning_bid', []);
  const winnningBid = _.first(winningBidList);
  const mostRecentBid = _.first(bidList);
  const order = _.findIndex(winningBidList, ['id', _.get(mostRecentBid, 'id')]);
  const bidStatsDisplay = () => {
    if (bidList.length == 0) {
      return <div className = "auction-notification box is-warning" >
        <h3 className="has-text-weight-bold is-flex">
        <span className="icon box__icon-marker is-medium has-margin-top-none">
          <i className="fas fa-lg fa-adjust"></i>
        </span>
        <span className="is-inline-block qa-supplier-bid-status-message">You haven't bid on this auction.</span>
        </h3>
      </div>;
    }
    else if (order == 0) {
      return <div className = "auction-notification box is-success" >
        <h3 className="has-text-weight-bold is-flex">
        <span className="icon box__icon-marker is-medium has-margin-top-none">
          <i className="fas fa-lg fa-check-circle"></i>
        </span>
        <span className="is-inline-block qa-supplier-bid-status-message">You're currently winning!</span>
        </h3>
      </div>;
    } else {
      if (order > 0) {
        return
 <div className = "auction-notification box is-success" >
          <h3 className="has-text-weight-bold is-flex">
          <span className="icon box__icon-marker is-medium has-margin-top-none">
            <i className="fas fa-lg fa-check-circle"></i>
          </span>
          <span className="is-inline-block qa-supplier-bid-status-message">You're in lowest bid position number {order + 1}</span>
          </h3>
        </div>;
      } else {
        return
 <div className = "auction-notification box is-warning" >
          <h3 className="has-text-weight-bold is-flex">
          <span className="icon box__icon-marker is-medium has-margin-top-none">
            <i className="fas fa-lg fa-times-circle"></i>
          </span>
          <span className="is-inline-block qa-supplier-bid-status-message">You've been outbid on this auction</span>
          </h3>
        </div>;
      }
    }
  }

  const winningBidListDisplay = () => {
    if (winningBidList.length > 0) {
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
              <td className="qa-auction-winning-bid-amount">${winnningBid.amount}</td>
              <td>{formatTime(winnningBid.time_entered)}</td>
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

