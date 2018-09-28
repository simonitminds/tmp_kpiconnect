import React from 'react';
import _ from 'lodash';
import { formatTime, formatPrice } from '../../utilities';

const BuyerLowestBid = ({auctionPayload}) => {
  const fuel = _.get(auctionPayload, 'auction.fuel.name');
  const lowestBidList = _.get(auctionPayload, 'lowest_bids', []);

  const lowestBidListDisplay = () => {
    if (lowestBidList.length > 0) {
      return (
        <table className="table table--lowest-bid is-fullwidth is-striped is-marginless">
          <thead>
            <tr>
              <th>Seller</th>
              <th>{fuel}</th>
              <th>Time</th>
            </tr>
          </thead>
          <tbody>
            {_.map(lowestBidList, (bid, is_traded_bid) => {
              return (
                <tr key={bid.id} className={`qa-auction-lowest-bid-${bid.id}`}>
                  <td className="qa-auction-lowest-bid-supplier">{bid.supplier}</td>
                  <td className="qa-auction-lowest-bid-amount">${formatPrice(bid.amount)} <span className="qa-auction-bid-is_traded_bid">{bid.is_traded_bid && <i action-label="Traded Bid" className="fas fa-exchange-alt has-margin-left-sm has-text-gray-3 auction__traded-bid-marker"></i>}</span></td>
                  <td>{formatTime(bid.time_entered)}</td>
                </tr>
              );
            })}
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
    <div className="box">
      <div className="box__subsection has-padding-bottom-none">
        <h3 className="box__header box__header--bordered">Lowest Bid(s)</h3>
        {lowestBidListDisplay()}
      </div>
    </div>
  );
};
export default BuyerLowestBid;
