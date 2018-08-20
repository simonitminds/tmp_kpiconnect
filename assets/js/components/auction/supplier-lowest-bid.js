import React from 'react';
import _ from 'lodash';
import SupplierBidStatus from './supplier-bid-status';
import SolutionDisplay from './solution-display';

const SupplierLowestBid = ({auctionPayload, connection}) => {
  const auctionStatus = _.get(auctionPayload, 'status');
  const fuels = _.get(auctionPayload, 'auction.fuels');
  const bestSolution = _.get(auctionPayload, 'solutions.best_overall');

  return(
    <div className="auction-lowest-bid">
      <SupplierBidStatus auctionPayload={auctionPayload} connection={connection} />
      <div className="box">
        <div className="box__subsection">
          <h3 className="box__header box__header--bordered">{auctionStatus == 'closed' ? `Winning Bid` : `Best Offer`}</h3>
          <SolutionDisplay auctionPayload={auctionPayload} solution={bestSolution} title="" />
        </div>
      </div>
    </div>
  );
};

export default SupplierLowestBid;
