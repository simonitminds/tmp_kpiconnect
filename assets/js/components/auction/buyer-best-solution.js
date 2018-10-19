import React from 'react';
import _ from 'lodash';
import { formatTime, formatPrice } from '../../utilities';
import SolutionComment from './solution-comment';
import SolutionDisplay from './solution-display';
import InputField from '../input-field';

const BuyerBestSolution = ({auctionPayload, acceptSolution}) => {
  const bestSolution = _.get(auctionPayload, 'solutions.best_overall');
  const bestSingleSupplier = _.get(auctionPayload, 'solutions.best_single_supplier');

  return(
    <div className="auction-solution__container">
      <div className="box">
        <div className="box__subsection has-padding-bottom-none">
          <h3 className="box__header box__header--bordered has-margin-bottom-md">Best Solution</h3>
          <SolutionDisplay auctionPayload={auctionPayload} solution={bestSolution} acceptSolution={acceptSolution} best={true} isExpanded={true} className="qa-auction-solution-best_overall" />
          <SolutionDisplay auctionPayload={auctionPayload} solution={bestSingleSupplier} acceptSolution={acceptSolution} isExpanded={true} className="qa-auction-solution-best_single_supplier" />
        </div>
      </div>
    </div>
  );
};

export default BuyerBestSolution;
