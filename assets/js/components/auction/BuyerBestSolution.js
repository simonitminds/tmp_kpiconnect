import React from 'react';
import _ from 'lodash';
import { formatTime, formatPrice } from '../../utilities';

const BuyerBestSolution = ({auctionPayload}) => {
  const fuel = _.get(auctionPayload, 'auction.fuel.name');
  const winningBid = _.get(auctionPayload, 'state.winning_bids[0]', {});
  const remainingBids = _.chain(auctionPayload)
    .get('bid_list', [])
    .reject(['id', winningBid.id])
    .orderBy(['amount', 'time_entered'],['asc', 'asc'])
    .value();

  const bidDisplay = (bid) => {
    return (
      <div className="auction-solution__header">
        <h3 className="auction-solution__title is-inline-block">{bid.supplier}</h3>
        <div className="auction-solution__content">
          <span className="has-text-weight-bold has-padding-right-xs">${formatPrice(bid.amount)}</span> ({formatTime(bid.time_entered)})
          <button disabled={auctionPayload.state.status == 'closed'} className="button is-small is-success has-margin-left-md">Accept Offer</button>
        </div>
      </div>
    );
  }

  const bestSolutionDisplay = () => {
    if (winningBid.id) {
      return (
        <div className={`box auction-solution auction-solution--best qa-best-solution-${winningBid.id}`}>
          {bidDisplay(winningBid)}
        </div>
      );
    } else {
      return <div className="auction-table-placeholder">
        <i>No bids had been placed on this auction</i>
      </div>;
    }
  }
  const otherSolutionDisplay = () => {
    if (remainingBids.length > 0) {
      return (
        <div className="box box--margin-bottom">
          <div className="box__subsection has-padding-bottom-none">
            <h3 className="box__header box__header--bordered">Other Solutions</h3>
          </div>

          {_.map(remainingBids, (bid) => {
            return (
              <div key={bid.id} className={`box auction-solution qa-other-solution-${bid.id}`}>
                {bidDisplay(bid)}
              </div>
            );
          })}
        </div>
      );
    }
    return
  }

  return(
    <div className="auction-solution__container">
      <div className="box">
        <div className="box__subsection has-padding-bottom-none">
          <h3 className="box__header box__header--bordered">Best Solution</h3>
          {bestSolutionDisplay()}
        </div>
      </div>
      {otherSolutionDisplay()}
    </div>
  );
};
export default BuyerBestSolution;
