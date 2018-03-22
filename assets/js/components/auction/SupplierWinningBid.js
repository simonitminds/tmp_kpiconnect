import React from 'react';
import _ from 'lodash';
import { formatTime, formatPrice } from '../../utilities';
import SupplierBidStatus from './SupplierBidStatus'

const SupplierWinningBid = ({auction}) => {
  const fuel = _.get(auction, 'fuel.name');
  const winningBid = _.chain(auction)
    .get('state.winning_bid')
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
      <SupplierBidStatus auction={auction} />
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
