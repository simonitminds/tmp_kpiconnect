import React from 'react';
import _ from 'lodash';
import { formatTime, formatPrice } from '../../utilities';
import SupplierBidStatus from './supplier-bid-status'

const SolutionDisplay = ({auctionPayload, solution, title}) => {
  const suppliers = _.get(auctionPayload, 'auction.suppliers');
  const fuels = _.get(auctionPayload, 'auction.fuels');
  const {bids, normalized_price, total_price, latest_time_entered} = solution;
  const fuelBids = _.map(bids, (bid) => {
    const fuel = _.find(fuels, (fuel) => fuel.id == bid.fuel_id);
    return {fuel, bid};
  });

  //TODO: maybe put this on the SolutionPayload
  const vesselFuels = _.get(auctionPayload, 'auction.auction_vessel_fuels');
  const fuelQuantities = _.chain(fuels)
      .reduce((acc, fuel) => {
        acc[fuel.id] = _.chain(vesselFuels).filter((vf) => vf.fuel_id == fuel.id).sumBy((vf) => vf.quantity).value();
        return acc;
      }, {})
      .value();
  const totalQuantity = _.sum(Object.values(fuelQuantities));

  return (
    <div className="box auction-solution qa-other-solution-79345c5649cd4233ac1ad2541c691c2a">
      <div className="auction-solution__header auction-solution__header--bordered">
        <h3 className="auction-solution__title is-inline-block"><i className="fas fa-minus has-padding-right-xs"></i> {title}</h3>
        <div className="auction-solution__content"><span className="has-text-weight-bold has-padding-right-xs">${formatPrice(normalized_price)}</span> ({formatTime(latest_time_entered)})</div>
      </div>
      <div className="auction-solution__body">
        <div>
          <table className="auction-solution__product-table table is-striped is-fullwidth">
            <thead>
              <tr>
                <th colSpan="3">Fuels</th>
              </tr>
            </thead>
            <tbody>
              {
                bids.length > 0  ?
                fuelBids.map(({fuel, bid}) => {
                  return (
                    <tr key={fuel.id}>
                      <td>{fuel.name}</td>

                      <td>
                        { bid ?
                          <span>
                            ${formatPrice(bid.amount)}
                            <span className="has-text-gray-3">/unit</span> &times; {fuelQuantities[fuel.id]} MT
                            <span className="qa-auction-bid-is_traded_bid"> {bid.is_traded_bid &&
                                <i action-label="Traded Bid" className="fas fa-exchange-alt has-margin-left-sm has-text-gray-3 auction__traded-bid-marker"></i>
                              }
                            </span>
                          </span> :
                          <i>No bid</i>
                        }
                      </td>
                      <td>{ true ? bid.supplier : "" }</td>
                    </tr>
                  );
                })

                : <tr>
                    <td>
                      <i>No bids had been placed on this auction</i>
                    </td>
                  </tr>
              }
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

export default SolutionDisplay;
