import React from 'react';
import _ from 'lodash';
import { formatTime, formatPrice } from '../../utilities';
import SupplierBidStatus from './supplier-bid-status'

const SupplierLowestBid = ({auctionPayload, connection}) => {
  const fuel = _.get(auctionPayload, 'auction.fuel.name');
  const auctionStatus = _.get(auctionPayload, 'auction.state.status');
  const lowestBid = _.chain(auctionPayload)
    .get('state.lowest_bids')
    .first()
    .value();

  const lowestBidListDisplay = () => {
    if (_.get(lowestBid, 'amount')) {
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
              <td className="qa-auction-lowest-bid-amount">${formatPrice(lowestBid.amount)}</td>
              <td>{formatTime(lowestBid.time_entered)}</td>
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
    <div className="auction-lowest-bid">
      <SupplierBidStatus auctionPayload={auctionPayload} connection={connection} />
      <div className="box">
        <div className="box__subsection">
          <h3 className="box__header box__header--bordered">{auctionStatus == 'closed' ? `Winning Bid` : `Best Offer`}</h3>
          {lowestBidListDisplay()}
        </div>
      </div>
    </div>
  );
};
export default SupplierLowestBid;
