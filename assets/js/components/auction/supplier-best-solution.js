import React from 'react';
import _ from 'lodash';
import SupplierBidStatus from './supplier-bid-status';
import SolutionDisplay from './solution-display';

const SupplierBestSolution = ({auctionPayload, connection, supplierId}) => {
  const auctionStatus = _.get(auctionPayload, 'status');
  const fuels = _.get(auctionPayload, 'auction.fuels');
  const bestSolution = _.get(auctionPayload, 'solutions.best_overall');
  const bestSingleSupplier = _.get(auctionPayload, 'solutions.best_single_supplier');
  const suppliersBestSolution = _.get(auctionPayload, 'solutions.suppliers_best_solution');

  const anySolutionExists = bestSolution || bestSingleSupplier || suppliersBestSolution;

  return(
    <div className="auction-lowest-bid">
      <SupplierBidStatus auctionPayload={auctionPayload} connection={connection} supplierId={supplierId} />
      <div className="box">
        <div className="box__subsection">
          <h3 className="box__header box__header--bordered">{auctionStatus == 'closed' ? `Winning Offer` : `Best Offers`}</h3>
          { bestSolution &&
            <SolutionDisplay auctionPayload={auctionPayload} solution={bestSolution} isExpanded={true} supplierId={supplierId} title="Best Overall Offer" />
          }
          { bestSingleSupplier &&
            <SolutionDisplay auctionPayload={auctionPayload} solution={bestSingleSupplier} isExpanded={true} supplierId={supplierId} title={`Best Single Supplier Offer`}/>
          }
        </div>
      </div>
      <div className="box">
        <div className="box__subsection">
          <h3 className="box__header box__header--bordered">Your Best Offer</h3>
          { suppliersBestSolution &&
            <SolutionDisplay auctionPayload={auctionPayload} solution={suppliersBestSolution} isExpanded={true} title="Your Best Offer" />
          }
          { !anySolutionExists &&
            <div class="auction-table-placeholder"><i>No bids have been placed on this auction</i></div>
          }
        </div>
      </div>
    </div>
  );
};

export default SupplierBestSolution;
