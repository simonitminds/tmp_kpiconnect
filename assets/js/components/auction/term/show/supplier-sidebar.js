import _ from 'lodash';
import React from 'react';
import { formatUTCDateTime } from '../../../../utilities';
import moment from 'moment';
import AuctionInvitation from '../../common/auction-invitation';
import SidebarDetails from './sidebar-details';
import BargeSubmission from '../../common/show/barge-submission';
import SupplierCOQs from '../../common/show/supplier-coqs';


const SupplierSidebar = (props) => {
  const {
    addCOQ,
    deleteCOQ,
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
      {(status == 'pending' || status == 'open') &&
        <AuctionInvitation auctionPayload={auctionPayload} supplierId={currentUserCompanyId} />
      }

      <BargeSubmission
        submitBargeForm={submitBargeForm}
        unsubmitBargeForm={unsubmitBargeForm}
        auctionPayload={auctionPayload}
        companyBarges={companyProfile.companyBarges}
        supplierId={currentUserCompanyId}
      />
      <SupplierCOQs
        addCOQ={addCOQ}
        deleteCOQ={deleteCOQ}
        auctionPayload={auctionPayload}
        supplierId={currentUserCompanyId}
        delivered={false}
      />
      <SidebarDetails auctionPayload={auctionPayload} isEditable={false} />
    </React.Fragment>
  );
};

export default SupplierSidebar;
