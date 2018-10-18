import React from 'react';
import _ from 'lodash';
import SupplierBidStatus from './supplier-bid-status';
import SolutionDisplay from './solution-display';

const SupplierLowestBid = ({auctionPayload, connection, supplierId}) => {
  const auctionStatus = _.get(auctionPayload, 'status');
  const fuels = _.get(auctionPayload, 'auction.fuels');
  const bestSolution = _.get(auctionPayload, 'solutions.best_overall');
  const bestSingleSupplier = _.get(auctionPayload, 'solutions.best_single_supplier');
  const suppliersBestSolution = _.get(auctionPayload, 'solutions.suppliers_best_solution');

  return(
    <div className="auction-lowest-bid">
      <SupplierBidStatus auctionPayload={auctionPayload} connection={connection} supplierId={supplierId} />
      <div className="box">
        <div className="box__subsection">
          <h3 className="box__header box__header--bordered">{auctionStatus == 'closed' ? `Winning Bid` : `Best Offer`}</h3>
          { bestSolution !== undefined ?
            <div>
              <SolutionDisplay auctionPayload={auctionPayload} solution={bestSolution} title="Best Overall Offer" />
              <SolutionDisplay auctionPayload={auctionPayload} solution={bestSingleSupplier} title={`Best Single Supplier Offer`}/>
              { suppliersBestSolution &&
                <SolutionDisplay auctionPayload={auctionPayload} solution={suppliersBestSolution} title="Your Best Offer" />
              }
            </div> :
            <div class="auction-table-placeholder"><i>No bids have been placed on this auction</i></div>
          }
        </div>
      </div>
    </div>
  );
};

export default SupplierLowestBid;
