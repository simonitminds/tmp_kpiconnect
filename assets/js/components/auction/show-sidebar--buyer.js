import _ from 'lodash';
import React from 'react';
import { formatUTCDateTime } from '../../utilities';
import moment from 'moment';
import AuctionLogLink from './auction-log-link';
import AuctionShowSidebarDetails from './show-sidebar-details';
import FuelRequirementDisplay from './fuel-requirement-display';
import InvitedSuppliers from './invited-suppliers';

const BuyerAuctionShowSidebar = (props) => {
  const {
    auctionPayload,
    approveBargeForm,
    rejectBargeForm
  } = props;

  const { auction, status } = auctionPayload;
  const vesselFuels = _.get(auction, 'auction_vessel_fuels');
  const isAdmin = window.isAdmin;
  const isEditable = status != 'open' && status != 'decision';

  return (
    <React.Fragment>
      <div className="box">
        <h3 className="box__header box__header--bordered has-margin-bottom-md">Auction Reports</h3>
        { (isAdmin && (status == 'closed' || status == 'expired')) &&
          <a className="button is-info has-family-copy has-margin-right-sm qa-admin-fixtures-link" href={`/admin/auctions/${auctionPayload.auction.id}/fixtures`}>View Fixtures</a>
        }
        { (isAdmin || (status != 'pending' && status != 'open')) &&
          <AuctionLogLink auction={auction} />
        }
      </div>
      <InvitedSuppliers
        auctionPayload={auctionPayload}
        approveBargeForm={approveBargeForm}
        rejectBargeForm={rejectBargeForm}
      />
      <AuctionShowSidebarDetails auctionPayload={auctionPayload} isEditable={isEditable} />
    </React.Fragment>
  );
};

export default BuyerAuctionShowSidebar;
