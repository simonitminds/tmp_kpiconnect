import _ from 'lodash';
import React from 'react';
import { formatUTCDateTime } from '../../../../utilities';
import moment from 'moment';
import AuctionInvitation from '../../common/auction-invitation';
import SidebarDetails from './sidebar-details';
import BargeSubmission from '../../common/show/barge-submission';
import COQSubmission from '../../common/show/coq-submission';


const SupplierSidebar = (props) => {
  const {
    auctionPayload,
    submitBargeForm,
    unsubmitBargeForm,
    currentUserCompanyId,
    companyProfile
  } = props;
  const { auction, status } = auctionPayload;
  const isAdmin = window.isAdmin;

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
      <COQSubmission
        auctionPayload={auctionPayload}
        supplierId={currentUserCompanyId}
      />
      <SidebarDetails auctionPayload={auctionPayload} isEditable={false} />
    </React.Fragment>
  );
};

export default SupplierSidebar;
