import React from 'react';
import _ from 'lodash';
import SupplierBidStatus from './supplier-bid-status';
import SolutionDisplay from './solution-display';

const SupplierBestSolution = ({auctionPayload, connection, supplierId, revokeBid}) => {
  const status = _.get(auctionPayload, 'status');
  const vesselFuels = _.get(auctionPayload, 'auction.auction_vessel_fuels');
  const bestSolution = _.get(auctionPayload, 'solutions.best_overall');
  const bestSingleSupplier = _.get(auctionPayload, 'solutions.best_single_supplier');
  const suppliersBestSolution = _.get(auctionPayload, 'solutions.suppliers_best_solution');
  const otherSolutions = _.get(auctionPayload, 'solutions.other_solutions');
  const suppliersBestSolutionBids = _.get(suppliersBestSolution, 'bids', []);
  const anySolutionExists = bestSolution || bestSingleSupplier || suppliersBestSolution;
  const bestPartialSolution = otherSolutions && otherSolutions[0]
  const isPartialSolution = suppliersBestSolutionBids.length < vesselFuels.length ? true : false;
  const noSolutionBids = suppliersBestSolutionBids.length == 0;

  const nextBestSolution =_.get(auctionPayload, 'solutions.next_best_solution');
  const otherSolution = () => {
    if (nextBestSolution && suppliersBestSolution) {
      return nextBestSolution.normalized_price < suppliersBestSolution.normalized_price ? nextBestSolution : suppliersBestSolution;
    } else if (nextBestSolution) {
      return nextBestSolution;
    } else if (suppliersBestSolution) {
      return suppliersBestSolution;
    } else {
      return null;
    }
  }


  return(
    <div className="auction-lowest-bid">
      { status == 'pending' ?
        <div className="box">
          <div className="box__subsection">
            <h3 className="box__header box__header--bordered">Your {status == 'pending' ? 'Opening Offer' : 'Best Offers'}</h3>
            <div className="auction-table-placeholder"><i>Any bids placed during the pending period will display upon auction start</i></div>
          </div>
        </div>
      : <div>
          <SupplierBidStatus auctionPayload={auctionPayload} connection={connection} supplierId={supplierId} />
          <div className="box">
            <div className="box__subsection">
              <h3 className="box__header box__header--bordered">{status == 'closed' ? `Winning Offer` : `Best Offers`}</h3>
              { bestSolution &&
                <SolutionDisplay auctionPayload={auctionPayload} solution={bestSolution} isExpanded={true} supplierId={supplierId} highlightOwn={true} title="Best Overall Offer" revokeBid={revokeBid} />
              }
              { bestSingleSupplier && vesselFuels && vesselFuels.length > 1 &&
                <SolutionDisplay auctionPayload={auctionPayload} solution={bestSingleSupplier} isExpanded={false} supplierId={supplierId} highlightOwn={true} title={`Best Single Supplier Offer`} revokeBid={revokeBid} />
              }
              { otherSolution() && isPartialSolution && vesselFuels && vesselFuels.length > 1 &&
                <SolutionDisplay auctionPayload={auctionPayload} solution={otherSolution()} isExpanded={false} supplierId={supplierId} highlightOwn={true} title={`Best Partial Offer`} revokeBid={revokeBid} />
              }
              { (!bestSolution && !otherSolution()) &&
                <div className="auction-table-placeholder"><i>No bids have been placed on this auction</i></div>
              }
            </div>
          </div>
        </div>
      }
    </div>
  );
};

export default SupplierBestSolution;
