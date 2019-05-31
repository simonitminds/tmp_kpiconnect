import _ from 'lodash';
import React from 'react';
import { formatUTCDateTime } from '../../../../utilities';
import moment from 'moment';
import LogLink from './log-link';
import SidebarDetails from './sidebar-details';
import InvitedSuppliers from '../../common/invited-suppliers';

const BuyerSidebar = (props) => {
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
        { (isAdmin || (status != 'pending')) &&
          <LogLink auction={auction} />
        }
      </div>
      <InvitedSuppliers
        auctionPayload={auctionPayload}
        approveBargeForm={approveBargeForm}
        rejectBargeForm={rejectBargeForm}
      />
      <SidebarDetails auctionPayload={auctionPayload} isEditable={isEditable} />
    </React.Fragment>
  );
};

export default BuyerSidebar;
