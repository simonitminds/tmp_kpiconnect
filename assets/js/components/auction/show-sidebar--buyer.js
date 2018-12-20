import _ from 'lodash';
import React from 'react';
import { formatUTCDateTime } from '../../utilities';
import moment from 'moment';
import AuctionLogLink from './auction-log-link';
import FuelRequirementDisplay from './fuel-requirement-display';
import InvitedSuppliers from './invited-suppliers';

const BuyerAuctionShowSidebar = (props) => {
  const {
    auctionPayload,
    approveBargeForm,
    rejectBargeForm
  } = props;

  const { auction, status } = auctionPayload;
  const isAdmin = window.isAdmin;
  const vesselFuels = _.get(auction, 'auction_vessel_fuels');

  return (
    <React.Fragment>
      { (isAdmin || (status != 'pending' && status != 'open')) &&
        <AuctionLogLink auction={auction} />
      }
      <InvitedSuppliers
        auctionPayload={auctionPayload}
        approveBargeForm={approveBargeForm}
        rejectBargeForm={rejectBargeForm}
      />
      <div className="box has-margin-bottom-md">
        <div className="box__subsection">
          <h3 className="box__header">Buyer Information
            <div className="field is-inline-block is-pulled-right">
            { status != 'open' && status != 'decision' &&
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
          <h3 className="box__header">Port Information</h3>
          <ul className="list has-no-bullets">
            <li className="is-not-flex">
              <strong className="is-block">{auction.port.name}</strong>
              <span className="is-block"><strong>ETA</strong> {formatUTCDateTime(auction.eta)}</span>
              <span className="is-block"><strong>ETD</strong> {formatUTCDateTime(auction.etd)}</span>
            </li>
            { auction.port_agent
              ? <li>
                  <strong className="is-block">Port Agent</strong>
                  <span className="qa-port_agent">{auction.port_agent}</span>
                </li>
              : <span className="qa-port_agent"></span>
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
    </React.Fragment>
  );
};

export default BuyerAuctionShowSidebar;
