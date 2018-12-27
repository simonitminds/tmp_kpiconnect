import _ from 'lodash';
import React from 'react';
import { formatUTCDateTime } from '../../utilities';
import moment from 'moment';
import AuctionLogLink from './auction-log-link';
import FuelRequirementDisplay from './fuel-requirement-display';
import InvitedSuppliers from './invited-suppliers';

const AuctionShowSidebarDetails = (props) => {
  const { auctionPayload, isEditable } = props;
  const { auction, status } = auctionPayload;
  const vesselFuels = _.get(auction, 'auction_vessel_fuels');
  const vessels = _.get(auction, 'vessels');

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

  return(
    <div className="box has-margin-bottom-md">
      <div className="box__subsection">
        <h3 className="box__header">Buyer Information
          <div className="field is-inline-block is-pulled-right">
          { isEditable &&
            <a className="button is-primary is-small has-family-copy is-capitalized" href={`/auctions/${auction.id}/edit`}>Edit</a>
          }
          </div>
        </h3>
        <ul className="list has-no-bullets">
          <li className="is-not-flex">
            <strong className="is-block">Organization</strong> {auction.buyer.name}
          </li>
          <li><strong>Buyer</strong> Buyer Name</li>
          <li><strong>Buyer Reference Number</strong> BRN</li>
        </ul>
      </div>
      <div className="box__subsection">
        <h3 className="box__header">Fuel Requirements</h3>
        <ul className="list has-no-bullets">
          <FuelRequirementDisplay vesselFuels={vesselFuels} />
        </ul>
      </div>
      <div className="box__subsection">
        <h3 className="box__header">Arrival Information</h3>
        <ul className="list has-no-bullets">
          <li className="is-not-flex">
            <strong>Port</strong>
            {auction.port.name}
          </li>
          { auction.port_agent
            ? <li className="is-not-flex">
                <strong>Port Agent</strong>
                <span className="qa-port_agent">{auction.port_agent || "Not Specified"}</span>
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
      </div>
      <div className="box__subsection">
        <h3 className="box__header">Additional Information</h3>
        <ul className="list has-no-bullets">
          <li>
            { auction.additional_information
              ? <span>{auction.additional_information}</span>
              : <i>No additional information provided.</i>
            }
          </li>
          { auction.anonymous_bidding &&
            <li className="qa-auction-anonymous_bidding">
              "Supplier bids on this auction are placed anonymously."
            </li>
          }
        </ul>
      </div>
    </div>
  );
};

export default AuctionShowSidebarDetails;
