import React from 'react';
import _ from 'lodash';
import { formatTime, formatPrice } from '../../utilities';

const BuyerBestSolution = ({auction}) => {
  const fuel = _.get(auction, 'fuel.name');
  const bidList = _.get(auction, 'bid_list', []);
  const winningBidList = _.get(auction, 'state.winning_bid', []);
  const bestSolutionDisplay = () => {
    console.log(auction.state.status)
    if (winningBidList.length > 0) {
      return (
        <div className="box auction-solution auction-solution--best">
          <div className="auction-solution__header">
            <h3 className="auction-solution__title is-inline-block">{winningBidList[0].supplier}</h3>
            <div className="auction-solution__content">
              <span className="has-text-weight-bold has-padding-right-xs">${formatPrice(winningBidList[0].amount)}</span> ({formatTime(winningBidList[0].time_entered)})
              <button disabled={auction.state.status == 'closed'} className="button is-small is-success has-margin-left-md">Accept Offer</button>
            </div>
          </div>
        </div>

      );
    } else {
      return <div className="auction-table-placeholder">
        <i>No bids had been placed on this auction</i>
      </div>;
    }
  }
  const otherSolutionDisplay = () => {
    if (bidList.length > 1) {
      return (
        <div className="box box--margin-bottom">
          <div className="box__subsection has-padding-bottom-none">
            <h3 className="box__header box__header--bordered">Other Solutions</h3>
          </div>

          {_.map(bidList, (bid) => {
            return (
              <div key={bid.id} className="box auction-solution">
                <div className="auction-solution__header">
                  <h3 className="auction-solution__title is-inline-block">{bid.supplier}</h3>
                  <div className="auction-solution__content">
                    <span className="has-text-weight-bold has-padding-right-xs">${formatPrice(bid.amount)}</span> ({formatTime(bid.time_entered)})
                    <button disabled={auction.state.status == 'closed'} className="button is-small is-success has-margin-left-md">Accept Offer</button>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      );
    }
    return
  }

  return(
    <div>
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
