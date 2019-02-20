import _ from 'lodash';
import React from 'react';
import { formatUTCDateTime, formatUTCDate } from '../../../../utilities';

const ArrivalInformationDisplay = (props) => {
  const {
    auction
  } = props;


  const vessels = _.get(auction, 'vessels');
  const port = _.get(auction, 'port');
  const portAgent = _.get(auction, 'port_agent');

  const vesselFuels = _.get(auction, 'auction_vessel_fuels');

  const vesselsWithETAs = _.map(vessels, (vessel) => {
    const vesselFuelsForVessel = _.filter(vesselFuels, {vessel_id: vessel.id});
    const eta = _.chain(vesselFuelsForVessel)
      .map('eta')
      .min()
      .value();
    const etd = _.chain(vesselFuelsForVessel)
      .filter({vessel_id: vessel.id})
      .map('etd')
      .min()
      .value();
    return { ...vessel, eta, etd };
  });


  return (
    <ul className="list has-no-bullets">
      <li className="is-not-flex">
        <strong>Port</strong>
        <span className="qa-auction-port">{port.name}</span>
      </li>
      { portAgent
        ? <li className="is-not-flex">
            <strong>Port Agent</strong>
            <span className="qa-port_agent">{portAgent}</span>
          </li>
        : <span className="qa-port_agent"></span>
      }
      { _.map(vesselsWithETAs, (vessel) => {
          return (
            <li className={`is-not-flex has-margin-top-md qa-auction-vessel-${vessel.id}`} key={vessel.id}>
              <strong className="is-block">{vessel.name}</strong>
              <span className="is-block"><strong>ETA</strong> {formatUTCDateTime(vessel.eta)}</span>
              <span className="is-block"><strong>ETD</strong> {formatUTCDateTime(vessel.etd)}</span>
            </li>
          );
        })
      }
    </ul>
  );
};

export default ArrivalInformationDisplay;
