import React from 'react';
import _ from 'lodash';
import { formatTime, formatPrice } from '../../utilities';
import SolutionDisplay from './solution-display';

const BuyerLowestBid = ({auctionPayload}) => {
  const fuel = _.get(auctionPayload, 'auction.fuel.name');
  const bestSolution = _.get(auctionPayload, 'solutions.best_overall');
  const bestSingleSupplier = _.get(auctionPayload, 'solutions.best_single_supplier');

  return(
    <div className="box">
      <div className="box__subsection has-padding-bottom-none">
        <h3 className="box__header box__header--bordered">Lowest Bid(s)</h3>
        <SolutionDisplay auctionPayload={auctionPayload} solution={bestSolution} title="Best Overall Offer" />
        <SolutionDisplay auctionPayload={auctionPayload} solution={bestSingleSupplier} title="Best Single Supplier" />
      </div>
    </div>
  );
};
export default BuyerLowestBid;
