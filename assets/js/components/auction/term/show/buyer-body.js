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

  if (status == 'open' || status == 'decision') {
    return (
      <div>
        { currentUser.isAdmin
          ? <RankedOffers auctionPayload={auctionPayload} solutions={rankedOffers} />
          : <RankedOffers auctionPayload={auctionPayload} solutions={rankedOffers} acceptSolution={acceptSolution} />
        }
        <BuyerGradeDisplay auctionPayload={auctionPayload} />
      </div>
    );
  } else if (status == 'closed') {
    return (
      <div>
        <WinningSolution auctionPayload={auctionPayload} />
        <RankedOffers auctionPayload={auctionPayload} solutions={rankedOffers} />
        <BuyerGradeDisplay auctionPayload={auctionPayload} />
      </div>
    );
  } else if (status == 'expired') {
    return (
      <div>
        <WinningSolution auctionPayload={auctionPayload} />
        { currentUser.isAdmin
          ? <RankedOffers auctionPayload={auctionPayload} solutions={rankedOffers} acceptSolution={acceptSolution} />
          : <RankedOffers auctionPayload={auctionPayload} solutions={rankedOffers} />
        }
        <BuyerGradeDisplay auctionPayload={auctionPayload} />
      </div>
    );
  } else {
    return (
      <div>
        <div className="auction-notification is-gray-0" >
          <h3 className="has-text-weight-bold">
          <span className="is-inline-block qa-supplier-bid-status-message">The auction has not started yet</span>
          </h3>
        </div>
        <RankedOffers auctionPayload={auctionPayload} solutions={rankedOffers} />
        <BuyerGradeDisplay auctionPayload={auctionPayload} />
      </div>
    );
  }
};

export default BuyerBody;
