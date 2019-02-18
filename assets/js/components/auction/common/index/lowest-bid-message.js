import _ from 'lodash';
import React from 'react';

const LowestBidMessage = ({auctionPayload}) => {
  const auctionStatus = _.get(auctionPayload, 'status');
  const bestSolution = _.get(auctionPayload, 'solutions.best_overall');
  const winningSolution = _.get(auctionPayload, 'solutions.winning_solution');

  if (winningSolution) {
    const suppliers = _.chain(winningSolution.bids).map("supplier").uniq().value();
    if(suppliers.length == 1) {
      return (
        <div className="card-content__best-bidder card-content__best-bidder--winner">
          <div className="card-content__best-bidder__name">Winner: {suppliers[0]}</div>
        </div>
      )
    } else {
      return (
        <div className="card-content__best-bidder card-content__best-bidder--winner">
          <div className="card-content__best-bidder__name">Winner: {suppliers[0]}</div><div className="card-content__best-bidder__count">(+{suppliers.length - 1})</div>
        </div>
      )
    }
  } else if (auctionStatus == 'expired') {
    return (
      <div className="card-content__best-bidder">
        <div className="card-content__best-bidder__name">No offer was selected</div>
      </div>
    )
  } else if (bestSolution) {
    const suppliers = _.chain(bestSolution.bids).map("supplier").uniq().value();
    return (
      <div className="card-content__best-bidder">
        <div className="card-content__best-bidder__name">Best Solution: {suppliers[0]}</div>{suppliers.length > 1 && <div className="card-content__best-bidder__count">(+{suppliers.length - 1})</div>}
      </div>
    )
  } else {
    return (
      <div className="card-content__best-bidder">
        Lowest Bid: <i>No bids yet</i>
      </div>
    )
  }
};

export default LowestBidMessage;
