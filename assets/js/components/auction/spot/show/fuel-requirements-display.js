import _ from 'lodash';
import React from 'react';

const FuelRequirementsDisplay = (props) => {
  const {
    auction
  } = props;


  const vessels = _.get(auction, 'vessels');

  const vesselFuels = _.get(auction, 'auction_vessel_fuels');
  const fuels = vesselFuels && _.chain(vesselFuels).map('fuel').uniqBy('id').value();

  if(fuels) {
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
      )}
    </ul>
  );
};

export default FuelRequirementsDisplay;
