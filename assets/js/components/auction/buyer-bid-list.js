import React from 'react';
import _ from 'lodash';
import { formatTime, formatPrice } from '../../utilities';

const BuyerBidList = ({auctionPayload, buyer}) => {
  const vesselFuels = _.chain(auctionPayload)
    .get('auction.auction_vessel_fuels')
    .reduce((acc, vesselFuel) => {
      acc[vesselFuel.id] = vesselFuel;
      return(acc);
    }, {})
    .value();

  const productBids = _.get(auctionPayload, 'product_bids');
  const products = _.chain(productBids)
    .keys()
    .sortBy([
      (vfId) => vesselFuels[vfId].fuel_id,
      (vfId) => vesselFuels[vfId].vessel_id
    ])
    .value();
  const bidList = _.chain(productBids)
    .map('lowest_bids')
    .flatten()
    .orderBy(['amount', 'time_entered'], ['asc', 'asc'])
    .value();

  if(bidList.length > 0) {
    return(
      <div className="box qa-buyer-bid-history">
        <h3 className="box__header box__header--bordered">Grade Display</h3>
        { _.map(products, (vfId) => {
            const lowestBids = productBids[vfId].lowest_bids;

            return(
              <table key={vfId} className="table table--grade-display is-fullwidth is-striped is-marginless">
                <thead>
                  <tr>
                    <th>{vesselFuels[vfId].fuel.name} for {vesselFuels[vfId].vessel.name}</th>
                    <th>Price</th>
                    <th>Time</th>
                  </tr>
                </thead>

                <tbody>
                  { _.map(lowestBids, ({id, amount, vfId, is_traded_bid, time_entered, supplier}) => {
                      return (
                        <tr key={id} className={`qa-auction-bid-${id}`}>
                          <td className="qa-auction-bid-supplier">{supplier}</td>
                          <td className="qa-auction-bid-amount"><span className="auction__bid-amount">${formatPrice(amount)}</span>
                            <span className="qa-auction-bid-is_traded_bid">
                              {is_traded_bid &&
                                <span className="auction__traded-bid-tag">
                                  <i action-label="Traded Bid" className="fas fa-exchange-alt auction__traded-bid-marker"></i>
                                  <span className="has-padding-left-sm">Traded Bid</span>
                                </span>
                              }
                            </span>
                          </td>
                          <td>({formatTime(time_entered)})</td>
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
  } else {
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
