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
      { vessels.length > 0
        ? <li className="is-not-flex">
            <strong>Vessels</strong>
            <span className="qa-auction-vessels">{vesselNames}</span>
          </li>
        : <span className="qa-auction-vessels"></span>
      }
    </ul>
  );
};

export default ArrivalInformationDisplay;

