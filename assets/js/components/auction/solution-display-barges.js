import React from 'react';
import _ from 'lodash';

const SolutionDisplayBarges = ({suppliers, bids, auctionBarges}) => {
  const bidSupplierIDs = _.chain(bids)
    .map((bid) => {
      if(bid.supplier_id) {
        return bid.supplier_id;
      } else {
        const supplier = _.find(suppliers, {name: bid.supplier});
        return supplier && supplier.id;
      }
    })
    .uniq()
    .value();

  const approvedAuctionBargesForSolution = _.chain(auctionBarges)
    .filter((auctionBarge) => _.includes(bidSupplierIDs, auctionBarge.supplier_id))
    .filter({approval_status: "APPROVED"})
    .value();


  if(approvedAuctionBargesForSolution.length > 0) {
    return (
      <div className="auction-solution__barge-list">
        {
          approvedAuctionBargesForSolution.map((auctionBarge) => {
            const barge = auctionBarge.barge;
            return (
              <span key={auctionBarge.id} className="auction-solution__barge">
                { barge.name } ({barge.imo_number})
              </span>
            );
          })
        }
      </div>
    );
  } else {
    return (
      <div className="auction-solution__barge-list">
        <i>None</i>
      </div>
    );
  }
};

export default SolutionDisplayBarges;
