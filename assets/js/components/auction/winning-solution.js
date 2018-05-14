import React from 'react';
import _ from 'lodash';
import { formatTime, formatPrice } from '../../utilities';
import SolutionComment from './solution-comment';

const WinningSolution = ({auctionPayload}) => {
  const auctionStatus = _.get(auctionPayload, 'state.status');
  const lowestBidId = _.get(auctionPayload, 'state.lowest_bids[0].id');
  const winningBid = _.get(auctionPayload, 'state.winning_bid');

  const winningSolutionDisplay = () => {
    if (winningBid) {
      return (
        <div>
          <div className={`box auction-solution auction-solution--best qa-winning-solution-${winningBid.id}`}>
            <div className="auction-solution__header">
              <h3 className="auction-solution__title is-inline-block">{winningBid.supplier}</h3>
              <div className="auction-solution__content">
                <span className="has-text-weight-bold has-padding-right-xs">
                  ${formatPrice(winningBid.amount)}
                </span> ({formatTime(winningBid.time_entered)})
              </div>
            </div>
          </div>
          <SolutionComment showInput={lowestBidId != winningBid.id} bid={winningBid} auctionStatus={auctionStatus} />
        </div>
      );
    } else {
      return <div className="auction-table-placeholder">
        <i>A winning bid was not selected before the decision time expired</i>
      </div>;
    }
  }

  return(
    <div className="auction-solution__container">
      <div className="box">
        <div className="box__subsection has-padding-bottom-none">
          <h3 className="box__header box__header--bordered">Winning Solution</h3>
          {winningSolutionDisplay()}
        </div>
      </div>
    </div>
  );
};
export default WinningSolution;
