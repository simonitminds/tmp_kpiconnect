import React from 'react';
import _ from 'lodash';
import { formatTime, formatPrice } from '../../../../utilities';
import SolutionDisplayWrapper from '../../common/show/solution-display-wrapper';
import SolutionDisplayBarges from '../../common/show/solution-display/solution-display-barges';
import TradedBidTag from '../../common/show/traded-bid-tag';

const SolutionDisplay = (props) => {
  const {auctionPayload, solution, title, acceptSolution, supplierId, revokeBid, highlightOwn, best, className} = props;
  const isSupplier = !!supplierId;
  const auctionBarges = _.get(auctionPayload, 'submitted_barges');
  const suppliers = _.get(auctionPayload, 'auction.suppliers');
  const {bids, normalized_price} = solution;
  // TODO: implement bid comments for conditions on the solution.
  const conditions = [];

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
      <div className="qa-solution-comments">
        { conditions.length > 0
          ? _.map(conditions, (condition) => {
              return (
                <div className="qa-solution-comment">
                  {condition}
                </div>
              );
            })
          : <div className="auction-table-placeholder has-margin-top-xs has-margin-bottom-sm qa-solution-no-comments">
              <p className="is-italic">No conditions have been placed on this offer.</p>
            </div>
        }
      </div>
    </SolutionDisplayWrapper>
  );
}

export default SolutionDisplay;
