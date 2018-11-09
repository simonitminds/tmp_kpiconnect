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
      { auctionStatus != 'pending' &&
        <SupplierBidStatus auctionPayload={auctionPayload} connection={connection} supplierId={supplierId} />
      }
      { auctionStatus != 'pending' &&
        <div className="box">
          <div className="box__subsection">
            <h3 className="box__header box__header--bordered">{auctionStatus == 'closed' ? `Winning Offer` : `Best Offers`}</h3>
            { bestSolution &&
              <SolutionDisplay auctionPayload={auctionPayload} solution={bestSolution} isExpanded={true} supplierId={supplierId} title="Best Overall Offer" />
            }
            { bestSingleSupplier && fuels && fuels.length > 1 &&
              <SolutionDisplay auctionPayload={auctionPayload} solution={bestSingleSupplier} isExpanded={true} supplierId={supplierId} title={`Best Single Supplier Offer`}/>
            }
            { !bestSolution &&
              <div className="auction-table-placeholder"><i>No bids have been placed on this auction</i></div>
            }
          </div>
        </div>
      }
      <div className="box">
        <div className="box__subsection">
          <h3 className="box__header box__header--bordered">Your {auctionStatus == 'pending' ? 'Opening Offer' : 'Best Offer'}</h3>
          { suppliersBestSolution &&
            <SolutionDisplay auctionPayload={auctionPayload} solution={suppliersBestSolution} isExpanded={true} title="Your Best Offer" />
          }
          { !suppliersBestSolution &&
            <div className="auction-table-placeholder"><i>You have not bid on this auction</i></div>
          }
        </div>
      </div>
    </div>
  );
};

export default SupplierBestSolution;
