import _ from 'lodash';
import React from 'react';
import { formatUTCDateTime } from '../../utilities';
import moment from 'moment';
import AuctionInvitation from './auction-invitation';
import BargeSubmission from './barge-submission';
import FuelRequirementDisplay from './fuel-requirement-display';


const SupplierAuctionShowSidebar = (props) => {
  const {
    auctionPayload,
    submitBargeForm,
    unsubmitBargeForm,
    currentUserCompanyId,
    companyProfile
  } = props;
  const { auction, status } = auctionPayload;
  console.log(status)
  const isAdmin = window.isAdmin;
  const vesselFuels = _.get(auction, 'auction_vessel_fuels');

  return (
    <React.Fragment>
      { (status == 'pending' || status == 'open') &&
        <AuctionInvitation auctionPayload={auctionPayload} supplierId={currentUserCompanyId} />
      }

      <BargeSubmission
        submitBargeForm={submitBargeForm}
        unsubmitBargeForm={unsubmitBargeForm}
        auctionPayload={auctionPayload}
        companyBarges={companyProfile.companyBarges}
        supplierId={currentUserCompanyId}
      />

      <div className="box has-margin-bottom-md">
        <div className="box__subsection">
          <h3 className="box__header">Buyer Information</h3>
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

export default SupplierAuctionShowSidebar;
