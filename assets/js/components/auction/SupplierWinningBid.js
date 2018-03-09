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
    if (order == 0) {
      return <span>You are currently winning!</span>
    } else {
      if (order > 0) {
        return <span>You are in bid position number {order + 1}</span>
      } else {
        return "";
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
      return <i>No bids placed</i>;
    }
  }

  return(
    <div className="box">
      <div className="box__subsection">
        <div>
          {bidStatsDisplay()}
        </div>
        <h3 className="box__header box__header--bordered">Winning Bid(s)</h3>
        {winningBidListDisplay()}
      </div>
    </div>
  );
};
export default SupplierWinningBid;
