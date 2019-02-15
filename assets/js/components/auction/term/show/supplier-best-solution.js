import React from 'react';
import _ from 'lodash';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import SupplierBidStatus from './supplier-bid-status';
import SolutionDisplay from './solution-display';

const SupplierBestSolution = ({auctionPayload, connection, supplierId, revokeBid}) => {
  const auctionStatus = _.get(auctionPayload, 'status');
  const fuel = _.get(auctionPayload, 'auction.fuel');
  const bestSolution = _.get(auctionPayload, 'solutions.best_overall');
  const suppliersBestSolution = _.get(auctionPayload, 'solutions.suppliers_best_solution');
  const nextBestSolution = _.get(auctionPayload, 'solutions.next_best_solution');

  const suppliersPrice = _.get(suppliersBestSolution, 'normalized_price') || 0;
  const nextBestPrice = _.get(nextBestSolution, 'normalized_price') || 0;

  const confirmBidRevoke = (ev) => {
    ev.preventDefault();
    const productId = ev.currentTarget.dataset.productId;
    const auctionId = auctionPayload.auction.id;

    return confirm(`Are you sure you want to cancel your bid?`) ? revokeBid(auctionId, productId) : false;
  };

  const supplierSolutionTitle = <span>
    Your Offer
    <span className={`tag revoke-bid__button qa-auction-product-${fuel.id}-revoke has-margin-left-sm`} onClick={confirmBidRevoke} data-product-id={fuel.id}>
      <FontAwesomeIcon icon="times" />
    </span>
  </span>;

  const supplierSection = suppliersBestSolution
      ? <SolutionDisplay key={"supplier"} auctionPayload={auctionPayload} solution={suppliersBestSolution} isExpanded={true} supplierId={supplierId} highlightOwn={true} title={supplierSolutionTitle} />
      : <div key={"supplier"} className="auction-table-placeholder"><i>You have not bid on this auction</i></div>;
  const competitorSection = nextBestSolution
      ? <SolutionDisplay key={"other"} auctionPayload={auctionPayload} solution={nextBestSolution} isExpanded={false} headerOnly={true} title="Competitor" />
      : <div key={"other"} className="auction-table-placeholder"><i>No other bids have been placed on this auction</i></div>;

  const orderedSections = suppliersPrice <= nextBestPrice
      ? [supplierSection, competitorSection]
      : [competitorSection, supplierSection];


  return(
    <div className="auction-lowest-bid">
      { auctionStatus != 'pending' &&
        <SupplierBidStatus auctionPayload={auctionPayload} connection={connection} supplierId={supplierId} />
      }

      <div className="box">
        <div className="box__subsection">
          <h3 className="box__header box__header--bordered">Ranked Offers</h3>
          { orderedSections }
        </div>
      </div>
    </div>
  );
};

export default SupplierBestSolution;
