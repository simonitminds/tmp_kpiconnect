import React from 'react';
import _ from 'lodash';
import { formatTime, formatPrice } from '../../utilities';
import SupplierBidStatus from './supplier-bid-status'
import SolutionComment from './solution-comment';

const SupplierWinningBid = ({auctionPayload, connection}) => {
  const auctionStatus = _.get(auctionPayload, 'status');
  const fuel = _.get(auctionPayload, 'auction.fuel.name');
  const winningBid = _.get(auctionPayload, 'winning_bid');

  const winningBidDisplay = () => {
    if (winningBid) {
      return (
        <div>
          <table className="table is-fullwidth is-striped is-marginless">
            <thead>
              <tr>
                <th>{fuel}</th>
                <th>Time</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td className="qa-auction-lowest-bid-amount">${formatPrice(winningBid.amount)}</td>
                <td>{formatTime(winningBid.time_entered)}</td>
              </tr>
            </tbody>
          </table>
          <SolutionComment showInput={winningBid.comment} bid={winningBid} auctionStatus={auctionStatus} />
        </div>
      );
    } else {
      return <div className="auction-table-placeholder">
        <i>A winning bid was not selected on this auction</i>
      </div>;
    }
  }

  return(
    <div className="auction-lowest-bid">
      <SupplierBidStatus auctionPayload={auctionPayload} connection={connection} />
      <div className="box">
        <div className="box__subsection">
          <h3 className="box__header box__header--bordered">Winning Bid</h3>
          {winningBidDisplay()}
        </div>
      </div>
    </div>
  );
};
export default SupplierWinningBid;
