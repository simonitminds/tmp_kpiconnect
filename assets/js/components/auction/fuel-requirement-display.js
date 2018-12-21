import _ from 'lodash';
import React from 'react';

const FuelRequirementDisplay = (props) => {
  const {
    vesselFuels
  } = props;
  const fuels = _.chain(vesselFuels).map('fuel').uniqBy('id').value();
  const vessels = _.chain(vesselFuels).map('vessel').uniqBy('id').value();

  if(fuels.length == 0) {
    return (
      <i>No fuels have been specified for this auction</i>
    );
  }

  return _.map(fuels, (fuel) => {
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
  });
};

export default FuelRequirementDisplay;
