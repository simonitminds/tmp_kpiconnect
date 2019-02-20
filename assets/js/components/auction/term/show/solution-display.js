import React from 'react';
import _ from 'lodash';
import { formatTime, formatPrice } from '../../../../utilities';
import SolutionDisplayWrapper from '../../common/show/solution-display-wrapper';
import SolutionDisplayBarges from '../../common/show/solution-display/solution-display-barges';
import TradedBidTag from '../../common/show/traded-bid-tag';
import SolutionComments from './solution-comments';
import CommentsDisplay from './comments-display';

const SolutionDisplay = (props) => {
  const {auctionPayload, solution, title, acceptSolution, supplierId, revokeBid, unsubmitComment, highlightOwn, best, className} = props;
  const isSupplier = !!supplierId;
  const auctionBarges = _.get(auctionPayload, 'submitted_barges');
  const suppliers = _.get(auctionPayload, 'auction.suppliers');
  const {bids, normalized_price} = solution;
  const comments = _.map(bids, 'comment');

  const hasTradedBid = _.some(bids, 'is_traded_bid');
  const price = `$${formatPrice(normalized_price)}`;
  const priceSection = hasTradedBid
      ? <span>
          <TradedBidTag className="has-margin-right-sm qa-auction-bid-is_traded_bid" />
          {price}
        </span>
      : price;

  return (
    <SolutionDisplayWrapper {...props} price={priceSection}>
      { _.map(bids, (bid) => <span key={bid.id} className={`qa-auction-bid-${bid.id}`}></span>) }

      { !isSupplier &&
        <div className="auction-solution__barge-section">
          <strong className="is-inline-block has-margin-right-sm">Approved Barges</strong>
          <SolutionDisplayBarges suppliers={suppliers} bids={bids} auctionBarges={auctionBarges} />
        </div>
      }

      <h3 className="has-text-weight-bold has-margin-top-md">Offer Conditions</h3>
      <SolutionComments solution={solution} />
      <CommentsDisplay auctionPayload={auctionPayload} unsubmitComment={unsubmitComment} />
    </SolutionDisplayWrapper>
  );
}

export default SolutionDisplay;
