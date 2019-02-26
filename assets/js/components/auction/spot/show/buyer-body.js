import _ from 'lodash';
import React from 'react';
import { formatUTCDateTime } from '../../../../utilities';
import moment from 'moment';
import AuctionInvitation from '../../common/auction-invitation';
import BargeSubmission from '../../common/show/barge-submission';
import BuyerBestSolution from './buyer-best-solution';
import BuyerGradeDisplay from './buyer-grade-display';
import OtherSolutions from './other-solutions';
import WinningSolution from './winning-solution';


const BuyerBody = (props) => {
  const {
    auctionPayload,
    currentUser,
    acceptSolution
  } = props;
  const { status, solutions } = auctionPayload;
  const otherSolutions = _.get(solutions, 'other_solutions');

  if (status == 'open') {
    return (
      <div>
        <BuyerBestSolution auctionPayload={auctionPayload} />
        <OtherSolutions auctionPayload={auctionPayload} solutions={otherSolutions} showCustom={false} />
        <BuyerGradeDisplay auctionPayload={auctionPayload} />
      </div>
    );
  } else if (status == 'decision') {
    return (
      <div>
        { currentUser.isAdmin
          ? <div>
              <BuyerBestSolution auctionPayload={auctionPayload} />
              <OtherSolutions auctionPayload={auctionPayload} solutions={otherSolutions} showCustom={false} />
            </div>
          : <div>
              <BuyerBestSolution auctionPayload={auctionPayload} acceptSolution={acceptSolution} />
              <OtherSolutions auctionPayload={auctionPayload} solutions={otherSolutions} acceptSolution={acceptSolution} showCustom={true} />
            </div>
        }
        <BuyerGradeDisplay auctionPayload={auctionPayload} />
      </div>
    );
  } else if(status ==  'closed') {
      return(
      <div>
        <WinningSolution auctionPayload={auctionPayload} />
        { currentUser.isAdmin
          ? <OtherSolutions auctionPayload={auctionPayload} solutions={otherSolutions} showCustom={false} />
          : <OtherSolutions auctionPayload={auctionPayload} solutions={otherSolutions} acceptSolution={acceptSolution} showCustom={false} />
        }
        <BuyerGradeDisplay auctionPayload={auctionPayload} />
      </div>
    );
  } else if(status == 'expired') {
      return(
      <div>
        { currentUser.isAdmin
              ? <div>
                  <BuyerBestSolution auctionPayload={auctionPayload} acceptSolution={acceptSolution} />
                  <OtherSolutions auctionPayload={auctionPayload} solutions={otherSolutions} acceptSolution={acceptSolution} showCustom={true} />
                </div>
              : <div>
                  <BuyerGradeDisplay auctionPayload={auctionPayload} />
                </div>
        }
     </div>
    );
  } else if(status == 'pending') {
    return (
      <div>
        <WinningSolution auctionPayload={auctionPayload} />
        { currentUser.isAdmin
          ? <OtherSolutions auctionPayload={auctionPayload} solutions={otherSolutions} showCustom={false} />
          : <OtherSolutions auctionPayload={auctionPayload} solutions={otherSolutions} acceptSolution={acceptSolution} showCustom={false} />
        }
        <BuyerGradeDisplay auctionPayload={auctionPayload} />
      </div>
    );
  } else {
    return (
      <div className="auction-notification is-gray-0" >
        <h3 className="has-text-weight-bold">
        <span className="is-inline-block qa-supplier-bid-status-message">The auction has not started yet</span>
        </h3>
      </div>
    );
  }
};

export default BuyerBody;
