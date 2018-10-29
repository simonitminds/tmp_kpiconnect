import React from 'react';
import _ from 'lodash';
import { formatTime, formatPrice } from '../../utilities';

const SupplierBidList = ({auctionPayload, buyer}) => {
  const fuels = _.chain(auctionPayload)
                .get('auction.fuels')
                 .reduce((acc, fuel) => {
                   acc[fuel.id] = fuel;
                   return(acc);
                 }, {})
                .value();
  const productBids = _.chain(auctionPayload)
                   .get('product_bids');

  const bidList = _.get(auctionPayload, 'bid_history', []);

    if (bidList.length > 0 ) {
      return(
        <div className="qa-supplier-bid-history box has-margin-top-lg">
          <h3 className="box__header box__header--bordered">Your Bid History</h3>
          <table className="table is-fullwidth is-striped is-marginless qa-auction-bidlist">
            <thead>
              <tr>
                <th>Product</th>
                <th>Amount </th>
                <th>Time</th>
              </tr>
            </thead>
            <tbody>
              {_.map(bidList, ({id, amount, min_amount, fuel_id, is_traded_bid, time_entered}) => {
                return (
                  <tr key={id} className={`qa-auction-bid-${id}`}>
                    <td className="qa-auction-bid-product">{fuels[fuel_id].name}</td>
                    <td className="qa-auction-bid-amount">
                      <span className="auction__bid-amount">${formatPrice(amount)}</span>
                      { min_amount &&
                        <i className="has-text-gray-4">(Min: ${formatPrice(min_amount)}) </i>
                      }
                      <span className="qa-auction-bid-is_traded_bid">{is_traded_bid &&
                        <span class="auction__traded-bid-tag">
                          <i action-label="Traded Bid" className="fas fa-exchange-alt has-margin-right-sm auction__traded-bid-marker"></i>
                          Traded Bid
                        </span>}
                      </span>
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
        <div className="qa-supplier-bid-history box">
          <h3 className="box__header box__header--bordered">Your Bid History</h3>
          <div className="auction-table-placeholder">
            <i>You have not bid on this auction</i>
          </div>
        </div>
      );
    }
};

export default SupplierBidList;
