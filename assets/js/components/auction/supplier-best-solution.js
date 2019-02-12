import React from 'react';
import _ from 'lodash';
import SupplierBidStatus from './supplier-bid-status';
import SolutionDisplay from './common/solution-display';

const SupplierBestSolution = ({auctionPayload, connection, supplierId, revokeBid}) => {
  const auctionStatus = _.get(auctionPayload, 'status');
  const vesselFuels = _.get(auctionPayload, 'auction.auction_vessel_fuels');
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
              <SolutionDisplay auctionPayload={auctionPayload} solution={bestSolution} isExpanded={true} supplierId={supplierId} highlightOwn={true} title="Best Overall Offer" />
            }
            { bestSingleSupplier && vesselFuels && vesselFuels.length > 1 &&
              <SolutionDisplay auctionPayload={auctionPayload} solution={bestSingleSupplier} isExpanded={false} supplierId={supplierId} highlightOwn={true} title={`Best Single Supplier Offer`}/>
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
            <SolutionDisplay auctionPayload={auctionPayload} solution={suppliersBestSolution} isExpanded={true} supplierId={supplierId} revokeBid={revokeBid} title="Your Best Offer" / >
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
