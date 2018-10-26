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
      <div className="box qa-buyer-bid-history">
        <h3 className="box__header box__header--bordered">Grade Display</h3>
        { _.map(products, (fuel_id) => {
            const lowestBids = productBids[fuel_id].lowest_bids;

            return (
              <table key={fuel_id} className="table is-fullwidth is-striped is-marginless">
                <thead>
                  <tr>
                    <th>{fuels[fuel_id].name}</th>
                    <th>Price</th>
                    <th>Time</th>
                  </tr>
                </thead>
                <tbody>

                  { _.map(lowestBids, ({id, amount, fuel_id, is_traded_bid, time_entered, supplier}) => {
                      return (
                        <tr key={id} className={`qa-auction-bid-${id}`}>
                          <td className="qa-auction-bid-supplier">{supplier}</td>
                          <td className="qa-auction-bid-amount"><span className="auction__bid-amount">${formatPrice(amount)}</span>
                            <span className="qa-auction-bid-is_traded_bid">
                              {is_traded_bid &&
                                <span className="auction__traded-bid-tag">
                                  <i action-label="Traded Bid" className="fas fa-exchange-alt has-margin-right-sm auction__traded-bid-marker"></i>
                                  Traded Bid
                                </span>
                              }
                            </span>
                          </td>
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
