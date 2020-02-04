import _ from 'lodash';
import React from 'react';
import { formatUTCDateTime } from '../../../../utilities';
import moment from 'moment';
import AuctionInvitation from '../../common/auction-invitation';
import BuyerBestSolution from './buyer-best-solution';
import BuyerGradeDisplay from './buyer-grade-display';
import OtherSolutions from './other-solutions';
import WinningSolution from './winning-solution';
import FullfillmentOptions from './fullfillment-options';

const BuyerBody = (props) => {
  const {
    addCOQ,
    deleteCOQ,
    auctionPayload,
    currentUser,
    acceptSolution
  } = props;
  const isObserver = window.isObserver;
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
        { !isObserver &&
          <FullfillmentOptions addCOQ={addCOQ} deleteCOQ={deleteCOQ} auctionPayload={auctionPayload} isSupplier={false} />
        }
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
        <div className="auction-notification is-gray-0" >
          <h3 className="has-text-weight-bold">
          <span className="is-inline-block qa-supplier-bid-status-message">A winning bid was not selected before the decision time expired</span>
          </h3>
        </div>
        { currentUser.isAdmin ?
          <div>
            <BuyerBestSolution auctionPayload={auctionPayload} acceptSolution={acceptSolution} />
            <OtherSolutions auctionPayload={auctionPayload} solutions={otherSolutions} acceptSolution={acceptSolution} showCustom={true} />
          </div> :
          <div>
            <BuyerBestSolution auctionPayload={auctionPayload} />
            <OtherSolutions auctionPayload={auctionPayload} solutions={otherSolutions} showCustom={false} />
          </div>
        }
        <BuyerGradeDisplay auctionPayload={auctionPayload} />
     </div>
    );
  } else if(status == 'pending') {
    return (
      <div>
        <div className="auction-notification is-gray-0" >
          <h3 className="has-text-weight-bold">
          <span className="is-inline-block qa-supplier-bid-status-message">The auction has not started yet</span>
          </h3>
        </div>
        <BuyerBestSolution auctionPayload={auctionPayload} />
        <OtherSolutions auctionPayload={auctionPayload} solutions={otherSolutions} showCustom={false} />
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
