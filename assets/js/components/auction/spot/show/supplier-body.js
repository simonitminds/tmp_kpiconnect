import _ from 'lodash';
import React from 'react';
import { formatUTCDateTime } from '../../../../utilities';
import moment from 'moment';
import AuctionInvitation from '../../common/auction-invitation';
import BidStatus from './bid-status';
import BiddingForm from './bidding-form';
import SupplierBestSolution from './supplier-best-solution';
import SupplierBidList from './supplier-bid-list';
import SupplierBidStatus from './supplier-bid-status';
import WinningSolution from './winning-solution';
import FullfillmentOptions from './fullfillment-options';


const SupplierBody = (props) => {
  const {
    addCOQ,
    deleteCOQ,
    auctionPayload,
    currentUser,
    connection,
    currentUserCompanyId,
    updateBidStatus,
    revokeSupplierBid,
    formSubmit
  } = props;
  const { status, message, solutions } = auctionPayload;
  const otherSolutions = _.get(solutions, 'other_solutions');

  if (status == 'open') {
    return (
      <div>
        { message && <BidStatus auctionPayload={auctionPayload} updateBidStatus={updateBidStatus} /> }
        <SupplierBestSolution auctionPayload={auctionPayload} connection={connection} revokeBid={revokeSupplierBid} supplierId={currentUserCompanyId} />
        <BiddingForm formSubmit={formSubmit} revokeBid={revokeSupplierBid} auctionPayload={auctionPayload} supplierId={currentUserCompanyId} />
        <SupplierBidList auctionPayload={auctionPayload} supplierId={currentUserCompanyId}  />
      </div>
    );
  } else if (status == 'decision') {
    return (
      <div>
        <SupplierBestSolution auctionPayload={auctionPayload} supplierId={currentUserCompanyId} revokeBid={revokeSupplierBid} />
        <SupplierBidList auctionPayload={auctionPayload} supplierId={currentUserCompanyId}  />
      </div>
    );
  } else if (status != 'pending') {
    return (
      <div>
        { message && <BidStatus auctionPayload={auctionPayload} updateBidStatus={updateBidStatus} /> }
        <SupplierBidStatus auctionPayload={auctionPayload} connection={connection} supplierId={currentUserCompanyId} />
        <FullfillmentOptions addCOQ={addCOQ} deleteCOQ={deleteCOQ} auctionPayload={auctionPayload} isSupplier={true} supplierId={currentUserCompanyId} />
        <WinningSolution auctionPayload={auctionPayload} supplierId={currentUserCompanyId} />
        <SupplierBidList auctionPayload={auctionPayload} supplierId={currentUserCompanyId} />
      </div>
    );
  } else {
    return (
      <div>
        <div className="auction-notification is-gray-0" >
          <h3 className="has-text-weight-bold is-flex">
            <span className="is-inline-block qa-supplier-bid-status-message">The auction has not started yet</span>
          </h3>
        </div>
        <SupplierBestSolution auctionPayload={auctionPayload} connection={connection} supplierId={currentUserCompanyId} />
        <BiddingForm formSubmit={formSubmit} revokeBid={revokeSupplierBid} auctionPayload={auctionPayload} supplierId={currentUserCompanyId} />
        <SupplierBidList auctionPayload={auctionPayload} supplierId={currentUserCompanyId} />
      </div>
    );
  }
};

export default SupplierBody;
