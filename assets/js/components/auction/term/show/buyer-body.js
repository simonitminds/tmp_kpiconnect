import _ from 'lodash';
import React from 'react';
import { formatUTCDateTime } from '../../../../utilities';
import moment from 'moment';
import AuctionInvitation from '../../common/auction-invitation';
import BargeSubmission from '../../common/show/barge-submission';
import BuyerGradeDisplay from './buyer-grade-display';
import RankedOffers from './ranked-offers';
import WinningSolution from './winning-solution';

const BuyerBody = (props) => {
  const {
    auctionPayload,
    currentUser,
    acceptSolution
  } = props;
  const { status, solutions } = auctionPayload;
  const rankedOffers = _.chain(solutions)
    .get('best_by_supplier')
    .values()
    .sortBy('normalized_price')
    .value();

  if (status == 'open') {
    return (
      <div>
        <RankedOffers auctionPayload={auctionPayload} solutions={rankedOffers} acceptSolution={acceptSolution} />
        <BuyerGradeDisplay auctionPayload={auctionPayload} />
      </div>
    );
  } else if (status != 'pending') {
    return (
      <div>
        <WinningSolution auctionPayload={auctionPayload} />
        <RankedOffers auctionPayload={auctionPayload} solutions={rankedOffers} acceptSolution={acceptSolution} />
        <BuyerGradeDisplay auctionPayload={auctionPayload} />
      </div>
    );
  } else {
    return (
      <div className="auction-notification box is-gray-0" >
        <h3 className="has-text-weight-bold">
        <span className="is-inline-block qa-supplier-bid-status-message">The auction has not started yet</span>
        </h3>
      </div>
    );
  }
};

export default BuyerBody;
