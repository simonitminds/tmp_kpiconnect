import _ from 'lodash';
import React from 'react';

const FuelRequirementsDisplay = (props) => {
  const {
    auction
  } = props;


  const auctionType = _.get(auction, 'type');
  const vessels = _.get(auction, 'vessels');

  switch(auctionType) {
    case 'spot':
      const vesselFuels = _.get(auction, 'auction_vessel_fuels');
      const fuels = _.chain(vesselFuels).map('fuel').uniqBy('id').value();

      if(fuels.length == 0) {
        return (
          <i>No fuels have been specified for this auction</i>
        );
      }

      return (
        <ul className="list has-no-bullets">
          { _.map(fuels, (fuel) => {
            return (
                <li className={`is-not-flex qa-auction-fuel-${fuel.id}`} key={fuel.id}>
                  <strong className="is-inline">{fuel.name}</strong>
                  <div className="qa-auction_vessel_fuels-quantities">
                    { _.map(vessels, (vessel) => {
                        let vesselFuel = _.find(vesselFuels, {'fuel_id': fuel.id, 'vessel_id': vessel.id});
                        if(vesselFuel) {
                          return(
                            <div key={vessel.id}>
                              { vesselFuel.quantity } MT to <span className="is-inline">{vessel.name}</span>
                            </div>
                          );
                        }
                      })
                    }
                  </div>
                </li>
              );
            }
          )};
        </ul>
      );

    case 'forward_fixed':
      const fuel = _.get(auction, 'fuel');
      const fuel_quantity = _.get(auction, 'fuel_quantity');

      return (
        <ul className="list has-no-bullets">
          <li className="is-not-flex">
            <strong>Fuel</strong>
            <span className="qa-auction-fuel">{fuel.name}</span>
          </li>
          <li className="is-not-flex">
            <strong>Quantity</strong>
            <span className="qa-auction-fuel_quantity">{fuel_quantity}</span> M/T
          </li>
        </ul>
      );

    case 'formula_related':
      return (<p>Formula related</p>);

    default:
      return null;
  }
};

export default FuelRequirementsDisplay;
