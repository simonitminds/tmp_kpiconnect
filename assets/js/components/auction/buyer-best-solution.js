import React from 'react';
import _ from 'lodash';
import { formatTime, formatPrice } from '../../utilities';
import SolutionDisplay from './solution-display';

const BuyerBestSolution = ({auctionPayload, acceptSolution}) => {
  const bestSolution = _.get(auctionPayload, 'solutions.best_overall');
  const bestSingleSupplier = _.get(auctionPayload, 'solutions.best_single_supplier');
  const fuels = _.get(auctionPayload, 'auction.fuels');

  return(
    <div className="auction-solution__container">
      <div className="box">
        <div className="box__subsection has-padding-bottom-none">
          <h3 className="box__header box__header--bordered has-margin-bottom-md">Best Offer(s)</h3>
          { bestSolution &&
            <SolutionDisplay auctionPayload={auctionPayload} solution={bestSolution} title="Best Overall" acceptSolution={acceptSolution} best={true} isExpanded={true} className="qa-auction-solution-best_overall" />
          }

          { fuels && fuels.length > 1 && bestSingleSupplier &&
              <SolutionDisplay auctionPayload={auctionPayload} solution={bestSingleSupplier} title="Best Single Supplier" acceptSolution={acceptSolution} isExpanded={true} className="qa-auction-solution-best_single_supplier" />
          }
          { !(bestSolution || bestSingleSupplier) &&
            <div className="auction-table-placeholder">
              <i>No bids have been placed on this auction</i>
            </div>
          }
        </div>
      </div>
    </div>
  );
};

export default BuyerBestSolution;
