import React from 'react';
import _ from 'lodash';
import { formatTime, formatPrice } from '../../../../utilities';
import SolutionDisplayWrapper from '../../common/show/solution-display-wrapper';
import SolutionDisplayBarges from '../../common/show/solution-display/solution-display-barges';

const SolutionDisplay = (props) => {
  const {auctionPayload, solution, title, acceptSolution, supplierId, revokeBid, highlightOwn, best, className} = props;
  const isSupplier = !!supplierId;
  const auctionBarges = _.get(auctionPayload, 'submitted_barges');
  const suppliers = _.get(auctionPayload, 'auction.suppliers');
  const {bids} = solution;
  // TODO: implement bid comments for conditions on the solution.
  const conditions = [];

  return (
    <SolutionDisplayWrapper {...props}>
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
          : <div className="qa-solution-no-comments">
              <p className="is-italic">No conditions have been placed on this offer.</p>
            </div>
        }
      </div>
    </SolutionDisplayWrapper>
  );
}

export default SolutionDisplay;
