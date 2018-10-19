import React from 'react';
import _ from 'lodash';
import { formatTime, formatPrice } from '../../utilities';

const BuyerBidList = ({auctionPayload, buyer}) => {
  const fuels = _.chain(auctionPayload)
                 .get('auction.fuels')
                 .reduce((acc, fuel) => {
                   acc[fuel.id] = fuel;
                   return(acc);
                 }, {})
                 .value();
  const productBids = _.get(auctionPayload, 'product_bids');
  const products = _.keys(productBids);
  const bidList = _.chain(productBids)
                   .map('lowest_bids')
                   .flatten()
                   .orderBy(['amount', 'time_entered'],['asc', 'asc'])
                   .value();

  if (bidList.length > 0) {
    return(
      <div className="box">
        <h3 className="box__header box__header--bordered">Grade Display</h3>
        { _.map(products, (fuel_id) => {
            const lowest_bids = productBids[fuel_id].lowest_bids;

            return (
              <table className="table is-fullwidth is-striped is-marginless qa-auction-bids">
                <thead>
                  <tr>
                    <th>{fuels[fuel_id].name}</th>
                    <th>Price</th>
                    <th>Time</th>
                  </tr>
                </thead>
                <tbody>

                  { _.map(lowest_bids, ({id, amount, min_amount, fuel_id, is_traded_bid, time_entered, supplier}) => {
                      return (
                        <tr key={id} className={`qa-auction-bid-${id}`}>
                          <td className="qa-auction-bid-supplier">{supplier}</td>
                          <td className="qa-auction-bid-amount">${formatPrice(amount)} <span className="qa-auction-bid-is_traded_bid">{is_traded_bid && <i action-label="Traded Bid" className="fas fa-exchange-alt has-margin-left-sm has-text-gray-3 auction__traded-bid-marker"></i>}</span></td>
                          <td>{formatTime(time_entered)}</td>
                        </tr>
                      );
                    })
                  }
                </tbody>
              </table>
            );
          })
        }
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
