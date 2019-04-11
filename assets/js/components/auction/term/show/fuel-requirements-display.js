import _ from 'lodash';
import React from 'react';

const FuelRequirementsDisplay = (props) => {
  const {
    auction
  } = props;
  const fuel = _.get(auction, 'fuel');
  const fuelQuantity = _.get(auction, 'fuel_quantity');
  const showTotalFuelVolume = _.get(auction, 'show_total_fuel_volume');
  const totalFuelVolume = _.get(auction, 'total_fuel_volume');

  if(fuel) {
    return (
      <ul className="list has-no-bullets">
        <li className="is-not-flex">
          <strong>Fuel</strong>
          <span className="qa-auction-fuel">{fuel.name}</span>
        </li>
        <li className="is-not-flex">
          <strong>Quantity</strong>
          { showTotalFuelVolume ?
              <div>
                <span className="qa-auction-total_fuel_volume">{totalFuelVolume}</span> MT (<span className="qa-auction-fuel_quantity">{fuelQuantity}</span> MT/month)
              </div>
            :
              <span><span className="qa-auction-fuel_quantity">{fuelQuantity}</span> MT/month</span>
          }
        </li>
      </ul>
    );
  }
  return(
    <i>No fuels have been specified for this auction</i>
  );
};

export default FuelRequirementsDisplay;
