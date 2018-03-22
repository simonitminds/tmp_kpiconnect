import React from 'react';
import _ from 'lodash';
import { formatTime, formatPrice } from '../../utilities';
import SupplierBidStatus from './SupplierBidStatus'

const SupplierWinningBid = ({auctionPayload}) => {
  const fuel = _.get(auctionPayload, 'auction.fuel.name');
  const winningBid = _.chain(auctionPayload)
    .get('state.winning_bids')
    .first()
    .value();

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
              <td className="qa-auction-winning-bid-amount">${formatPrice(winningBid.amount)}</td>
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
    <div className="auction-winning-bid">
      <SupplierBidStatus auctionPayload={auctionPayload} />
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
