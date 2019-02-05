import _ from 'lodash';
import React from 'react';
import { formatUTCDateTime, formatUTCDate } from '../../../utilities';

const ArrivalInformationDisplay = (props) => {
  const {
    auction
  } = props;


  const auctionType = _.get(auction, 'type');
  const vessels = _.get(auction, 'vessels');
  const port = _.get(auction, 'port');
  const portAgent = _.get(auction, 'port_agent');

  switch(auctionType) {
    case 'spot':
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
            {port.name}
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
                <li className="is-not-flex has-margin-top-md" key={vessel.id}>
                  <strong className="is-block">{vessel.name}</strong>
                  <span className="is-block"><strong>ETA</strong> {formatUTCDateTime(vessel.eta)}</span>
                  <span className="is-block"><strong>ETD</strong> {formatUTCDateTime(vessel.etd)}</span>
                </li>
              );
            })
          }
        </ul>
      );

    case 'forward_fixed':
      const terminal = _.get(auction, 'terminal');
      const startDate = formatUTCDate(_.get(auction, 'start_date'));
      const endDate = formatUTCDate(_.get(auction, 'end_date'));
      const vesselNames = _.chain(vessels).map('name').join(", ").value();

      return (
        <ul className="list has-no-bullets">
          <li className="is-not-flex">
            <strong>Port</strong>
            <span className="qa-auction-port">{port.name}</span>
          </li>
          { portAgent
            ? <li className="is-not-flex">
                <strong>Port Agent</strong>
                <span className="qa-auction-port_agent">{portAgent}</span>
              </li>
            : <span className="qa-auction-port_agent"></span>
          }
          { terminal
            ? <li className="is-not-flex">
                <strong>Terminal/Anchorage</strong>
                <span className="qa-auction-terminal">{terminal}</span>
              </li>
            : <span className="qa-auction-terminal"></span>
          }
          <li className="is-not-flex">
            <strong>Start Month</strong>
            <span className="qa-auction-start_date">{startDate}</span>
          </li>
          <li className="is-not-flex">
            <strong>End Date</strong>
            <span className="qa-auction-end_date">{endDate}</span>
          </li>
          { vessels
            ? <li className="is-not-flex">
                <strong>Vessels</strong>
                <span className="qa-auction-vessels">{vesselNames}</span>
              </li>
            : <span className="qa-auction-vessels"></span>
          }
        </ul>
      );

    case 'formula_related':
      return (<p>Formula related</p>);

    default:
      return null;
  }
};

export default ArrivalInformationDisplay;
