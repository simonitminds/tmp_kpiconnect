import React from 'react';
import _ from 'lodash';
import { formatTime, formatPrice } from '../../utilities';

const BuyerBidList = ({auctionPayload, buyer}) => {
  const fuel = _.get(auctionPayload, 'auction.fuel.name');
  const bidList = _.get(auctionPayload, 'bid_list', []);
  const lowestBidIds = _.chain(auctionPayload)
    .get('state.lowest_bids', [])
    .map('id')
    .value();

  const lowestBid = (bidId) => {
    if (_.includes(lowestBidIds, bidId)) {
      return "is-selected";
    }
  }

  if (bidList.length > 0) {
    return(
      <div className="box">
        <h3 className="box__header box__header--bordered">Grade Display</h3>
        <table className="table is-fullwidth is-striped is-marginless qa-auction-bids">
          <thead>
            <tr>
              <th>Seller</th>
              <th>{fuel}</th>
              <th>Time</th>
            </tr>
          </thead>
          <tbody>
            {_.map(bidList, (bid) => {
              return (
                <tr key={bid.id}
                    className={`${lowestBid(bid.id)} qa-auction-bid-${bid.id}`}
                >
                  <td className="qa-auction-bid-supplier">{bid.supplier}</td>
                  <td className="qa-auction-bid-amount">${formatPrice(bid.amount)}</td>
                  <td>{formatTime(bid.time_entered)}</td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    );
  }

  else {
    return(
      <div className="box">
        <h3 className="box__header box__header--bordered">Grade Display</h3>
        <div className="auction-table-placeholder">
          <i>No bids have been placed on this auction</i>
        </div>
      </div>
    );
  }
};

export default BuyerBidList;
