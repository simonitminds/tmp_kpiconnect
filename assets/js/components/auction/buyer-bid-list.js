import React from 'react';
import _ from 'lodash';
import { formatTime, formatPrice } from '../../utilities';

const BuyerBidList = ({auctionPayload, buyer}) => {
  const fuel = _.get(auctionPayload, 'auction.fuel.name');
  const bidList = _.get(auctionPayload, 'bid_history', []);
  const lowestBidIds = _.chain(auctionPayload)
    .get('lowest_bids', [])
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
            {_.map(bidList, ({id, amount, min_amount, is_traded_bid, time_entered, supplier}) => {
              return (
                <tr key={id}
                    className={`${lowestBid(id)} qa-auction-bid-${id}`}
                >
                  <td className="qa-auction-bid-supplier">{supplier}</td>
                  <td className="qa-auction-bid-amount">${formatPrice(amount)} <span className="qa-auction-bid-is_traded_bid">{is_traded_bid && <i action-label="Traded Bid" className="fas fa-exchange-alt has-margin-left-sm has-text-gray-3 auction__traded-bid-marker"></i>}</span>
</td>
                  <td>{formatTime(time_entered)}</td>
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
