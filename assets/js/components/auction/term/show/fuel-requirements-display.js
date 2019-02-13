import _ from 'lodash';
import React from 'react';

const FuelRequirementsDisplay = (props) => {
  const {
    auction
  } = props;
  const fuel = _.get(auction, 'fuel');
  const fuelQuantity = _.get(auction, 'fuel_quantity');

  return (
    <ul className="list has-no-bullets">
      <li className="is-not-flex">
        <strong>Fuel</strong>
        <span className="qa-auction-fuel">{fuel.name}</span>
      </li>
      <li className="is-not-flex">
        <strong>Quantity</strong>
        <span className="qa-auction-fuel_quantity">{fuelQuantity}</span> MT
      </li>
    </ul>
  );
};

export default FuelRequirementsDisplay;
