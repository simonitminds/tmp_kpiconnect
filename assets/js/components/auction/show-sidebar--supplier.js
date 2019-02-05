import _ from 'lodash';
import React from 'react';
import { formatUTCDateTime } from '../../utilities';
import moment from 'moment';
import AuctionInvitation from './auction-invitation';
import AuctionShowSidebarDetails from './show-sidebar-details';
import BargeSubmission from './barge-submission';


const SupplierAuctionShowSidebar = (props) => {
  const {
    auctionPayload,
    submitBargeForm,
    unsubmitBargeForm,
    currentUserCompanyId,
    companyProfile
  } = props;
  const { auction, status } = auctionPayload;
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
      <AuctionShowSidebarDetails auctionPayload={auctionPayload} isEditable={false} />
    </React.Fragment>
  );
};

export default SupplierAuctionShowSidebar;
