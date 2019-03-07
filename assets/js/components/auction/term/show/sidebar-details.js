import _ from 'lodash';
import React from 'react';
import { formatUTCDateTime } from '../../../../utilities';
import moment from 'moment';
import LogLink from './log-link';
import FuelRequirementsDisplay from './fuel-requirements-display';
import ArrivalInformationDisplay from './arrival-information-display';
import InvitedSuppliers from '../../common/invited-suppliers';

const SidebarDetails = (props) => {
  const { auctionPayload, isEditable } = props;
  const { auction, status } = auctionPayload;

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
          <li><strong>Buyer</strong> {auction.buyer.contact_name}</li>
          <li><strong>Buyer Reference Number</strong> &mdash;</li>
        </ul>
      </div>
      <div className="box__subsection">
        <h3 className="box__header">Fuel Requirements</h3>
        <FuelRequirementsDisplay auction={auction} />
      </div>
      <div className="box__subsection">
        <h3 className="box__header">Arrival Information</h3>
        <ArrivalInformationDisplay auction={auction} />
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

export default SidebarDetails;
