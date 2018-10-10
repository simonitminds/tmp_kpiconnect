import React from 'react';
import _ from 'lodash';
import { formatTime, formatPrice } from '../../utilities';
import SolutionComment from './solution-comment';
import SolutionDisplay from './solution-display';
import InputField from '../input-field';

const OtherSolutions = ({auctionPayload, solutions, acceptBid}) => {
  const auctionStatus = _.get(auctionPayload, 'status');
  const lowestBid = _.get(auctionPayload, 'lowest_bids[0]');
  const lowestBidId = _.get(lowestBid, 'id');
  const winningBidId = _.get(auctionPayload, 'winning_bid.id');
  const is_traded_bid = _.get(auctionPayload, 'lowest_bids.is_traded_bid');
  const remainingBids = _.chain(auctionPayload)
    .get('bid_history', [])
    .reject(['id', lowestBidId])
    .reject(['id', winningBidId])
    .orderBy(['amount', 'time_entered'],['asc', 'asc'])
    .value();
  const onSelectSolution = (bidIds) => { this.setState({bidIds: bidIds}) }

  return(
    <div className="auction-solution__container">
      <div className="box">
        <div className="box__subsection has-padding-bottom-none">
          <h3 className="box__header box__header--bordered has-margin-bottom-md">Other Solutions</h3>
          { _.map(solutions, (solution) => {
              return (
                <SolutionDisplay auctionPayload={auctionPayload} solution={solution} acceptBid={acceptBid} best={false} />
              );
            })
          }
        </div>
      </div>
    </div>
  );
};

export default OtherSolutions;
