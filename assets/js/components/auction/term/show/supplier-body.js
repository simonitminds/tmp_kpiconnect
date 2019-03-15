import _ from 'lodash';
import React from 'react';
import MediaQuery from 'react-responsive';
import { formatUTCDateTime } from '../../../../utilities';
import moment from 'moment';
import BidStatus from './bid-status';
import BiddingForm from './bidding-form';
import CommentForm from './comment-form';
import SupplierBestSolution from './supplier-best-solution';
import SupplierBidList from './supplier-bid-list';
import SupplierBidStatus from './supplier-bid-status';
import WinningSolution from './winning-solution';
import CollapsibleSection from '../../common/collapsible-section';


const SupplierBody = (props) => {
  const {
    auctionPayload,
    currentUser,
    connection,
    currentUserCompanyId,
    updateBidStatus,
    revokeSupplierBid,
    formSubmit,
    removeCommentFromSolution,
    addCommentToSolution
  } = props;
  const { status, message, solutions } = auctionPayload;
  const otherSolutions = _.get(solutions, 'other_solutions');

  if (status == 'open') {
    return (
      <div>
        { message && <BidStatus auctionPayload={auctionPayload} updateBidStatus={updateBidStatus} /> }
        <SupplierBestSolution auctionPayload={auctionPayload}
          connection={connection}
          revokeBid={revokeSupplierBid}
          unsubmitComment={removeCommentFromSolution}
          supplierId={currentUserCompanyId} />
        <div className={`auction-bidding ${status == 'pending'? `auction-bidding--pending` : ``} box box--nested-base`}>
          <MediaQuery query="(min-width: 769px)">
            <BiddingForm formSubmit={formSubmit} revokeBid={revokeSupplierBid} auctionPayload={auctionPayload} supplierId={currentUserCompanyId} />
            <CommentForm addCommentToSolution={addCommentToSolution}
              auctionPayload={auctionPayload}
              supplierId={currentUserCompanyId}
              unsubmitComment={removeCommentFromSolution} />
          </MediaQuery>
          <MediaQuery query="(max-width: 768px)">
            <CollapsibleSection
              trigger="Place Bid"
              classParentString="collapsing-auction-bidding"
              open={true}
            >
            <BiddingForm formSubmit={formSubmit} revokeBid={revokeSupplierBid} auctionPayload={auctionPayload} supplierId={currentUserCompanyId} />
            <CommentForm addCommentToSolution={addCommentToSolution}
              auctionPayload={auctionPayload}
              supplierId={currentUserCompanyId}
              unsubmitComment={removeCommentFromSolution} />
            </CollapsibleSection>
          </MediaQuery>
        </div>
        <SupplierBidList auctionPayload={auctionPayload} supplierId={currentUserCompanyId}  />
      </div>
    );
  } else if (status != 'pending') {
    return (
      <div>
        { message && <BidStatus auctionPayload={auctionPayload} updateBidStatus={updateBidStatus} /> }
        <SupplierBidStatus auctionPayload={auctionPayload}
          connection={connection}
          supplierId={currentUserCompanyId} />
        <WinningSolution auctionPayload={auctionPayload} supplierId={currentUserCompanyId} />
        <BiddingForm formSubmit={formSubmit} revokeBid={revokeSupplierBid} auctionPayload={auctionPayload} supplierId={currentUserCompanyId} />
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
        <SupplierBestSolution auctionPayload={auctionPayload}
          connection={connection}
          revokeBid={revokeSupplierBid}
          unsubmitComment={removeCommentFromSolution}
          supplierId={currentUserCompanyId} />
        <div className={`auction-bidding ${status == 'pending'? `auction-bidding--pending` : ``} box box--nested-base`}>
          <MediaQuery query="(min-width: 769px)">
            <BiddingForm formSubmit={formSubmit} revokeBid={revokeSupplierBid} auctionPayload={auctionPayload} supplierId={currentUserCompanyId} />
            <CommentForm addCommentToSolution={addCommentToSolution} auctionPayload={auctionPayload} unsubmitComment={removeCommentFromSolution} />
          </MediaQuery>
          <MediaQuery query="(max-width: 768px)">
            <CollapsibleSection
              trigger="Place Bid"
              classParentString="collapsing-auction-bidding"
              open={true}
            >
              <BiddingForm formSubmit={formSubmit} revokeBid={revokeSupplierBid} auctionPayload={auctionPayload} supplierId={currentUserCompanyId} />
              <CommentForm addCommentToSolution={addCommentToSolution} auctionPayload={auctionPayload} unsubmitComment={removeCommentFromSolution} />
            </CollapsibleSection>
          </MediaQuery>
        </div>
        <SupplierBidList auctionPayload={auctionPayload} supplierId={currentUserCompanyId} />
      </div>
    );
  }
};

export default SupplierBody;
