import _ from 'lodash';
import React from 'react';
import { formatPrice } from '../../../../utilities';

const FuelIndexDisplay = ({auction}) => {
  const fuelIndex = _.get(auction, 'fuel_index');
  const currentIndexPrice = _.get(auction, 'current_index_price')

  return (
    <ul className="list has-no-bullets">
      <li className="is-not-flex">
        <strong>Name</strong>
        <span className="qa-auction-fuel_index">{fuelIndex ? fuelIndex.name : "—"}</span>
      </li>
      <li className="is-not-flex">
        <strong>Code</strong>
        <span className="qa-auction-fuel_index_code">{fuelIndex ? fuelIndex.code : "—"}</span>
      </li>
      <li className="is-not-flex">
        <strong>Latest Index Price</strong>
        <span className="qa-auction-current_index_price">{currentIndexPrice ? "$" + formatPrice(currentIndexPrice) : "—"}</span>
      </li>
    </ul>
  );
}
export default FuelIndexDisplay;
