import React from 'react';
import _ from 'lodash';
import { quickOrdinal } from '../../../../utilities';

const SupplierBidStatus = ({auctionPayload, connection, supplierId}) => {
  const supplierIdInt = parseInt(supplierId);
  const bidList = _.get(auctionPayload, 'bid_history', []);
  const hasActiveBid = (_.filter(bidList, 'active').length > 0);

  const auctionFuels = _.get(auctionPayload, 'auction.fuels');
  const vesselFuels = _.get(auctionPayload, 'auction.auction_vessel_fuels');

  const suppliersBestSolution = _.get(auctionPayload, 'solutions.suppliers_best_solution');
  const bestSingleSolution = _.get(auctionPayload, 'solutions.best_single_supplier');

  const bestSingleSolutionBids = _.get(bestSingleSolution, 'bids');
  const bestSingleSolutionSupplierIds = _.map(bestSingleSolutionBids, 'supplier_id');
  const isBestSingleSolution = _.includes(bestSingleSolutionSupplierIds, supplierIdInt);

  const bestOverallSolution = _.get(auctionPayload, 'solutions.best_overall');
  const bestOverallSolutionBids = _.get(bestOverallSolution, 'bids');
  const bestOverallProductsForSupplier = _.chain(bestOverallSolutionBids)
        .filter({'supplier_id': supplierIdInt})
        .map((bid) => {
          const vesselFuel = _.find(vesselFuels, (vf) =>  `${vf.id}` == bid.vessel_fuel_id);
          return vesselFuel;
        })
        .value();

  const bestSolutionSupplierIds = _.map(bestOverallSolutionBids, 'supplier_id');
  const isInBestSolution = _.includes(bestSolutionSupplierIds, supplierIdInt);
  const isBestOverallSolution = !_.some(bestSolutionSupplierIds, (id) => id != supplierIdInt);

  const winningSolutionBids = _.get(auctionPayload, "solutions.winning_solution.bids");
  const winningSolutionSupplierIds = _.map(winningSolutionBids, 'supplier_id');
  const winningSolutionProductsForSupplier = _.chain(winningSolutionBids)
        .filter({'supplier_id': supplierIdInt})
        .map((bid) => {
          const vesselFuel = _.find(vesselFuels, (vf) =>  `${vf.id}` == bid.vessel_fuel_id);
          return vesselFuel;
        })
        .value();
  const isInWinningSolution = _.includes(winningSolutionSupplierIds, supplierIdInt);
  const isWinningSolution = !_.some(winningSolutionSupplierIds, (id) => id != supplierIdInt);

  const singleSolutionIsTied = suppliersBestSolution && bestSingleSolution &&
    !isBestSingleSolution && (bestSingleSolution.normalized_price == suppliersBestSolution.normalized_price);
  const auctionStatus = _.get(auctionPayload, 'status');

  const productPortionString = (products) => {
    if(products.length == vesselFuels.length && vesselFuels.length != 1) {
      return "every deliverable";
    } else if(products.length == 1) {
      return "one deliverable";
    } else if(products.length > 0) {
      return `${products.length} of ${vesselFuels.length} deliverables`;
    } else {
      return "no deliverables";
    }
  }

  const productNameString = (products) => {
    const fuelNames = _.chain(products)
      .map('fuel.name')
      .uniq()
      .value();

    const fuelCount = fuelNames.length;

    if(fuelNames.length == 1) {
      return fuelNames[0];
    } else {
      return _.reduce(fuelNames, (acc, fuel, index) => {
          const delim = (fuelCount <= 2) ? " and " : ((index == fuelCount - 1) ? ", and " : ", ");
          return acc + delim + fuel;
        });
    }
  }

  const messageDisplay = (message) => {
    return (
      <h3 className="has-margin-bottom-none">
        <span className="auction-notification__copy qa-supplier-bid-status-message">
          {message}
        </span>
      </h3>
    );
  }

  if(auctionStatus == "pending") {
    return <i>The auction has not started</i>;
  } else if (auctionStatus == "expired") {
    return (
      <div className="auction-notification is-gray-3">
        {messageDisplay("No offer was selected")}
      </div>
    );
  } else if (auctionStatus == "closed" && isWinningSolution) {
    return (
      <div className="auction-notification is-success">
        <div className="auction-notification__show-message">
          {messageDisplay(`You won the entire auction`)}
        </div>
        <div className="auction-notification__card-message">
          {messageDisplay(`You won the auction`)}
        </div>
      </div>
    );
  } else if (auctionStatus == "closed" && isInWinningSolution) {
    return (
      <div className="auction-notification is-success">
        <div className="auction-notification__show-message">
          {messageDisplay(`You won bids for ${productNameString(winningSolutionProductsForSupplier)} in this auction`)}
        </div>
        <div className="auction-notification__card-message">
          {messageDisplay(`You won ${productPortionString(winningSolutionProductsForSupplier)} in this auction`)}
        </div>
      </div>
    );
  } else if (auctionStatus == "closed" && !isInWinningSolution) {
    return (
      <div className="auction-notification is-danger">
        <div className="auction-notification__show-message">
          {messageDisplay("Regretfully, you were unsuccessful in this auction. Thank you for quoting")}
        </div>
        <div className="auction-notification__card-message">
          {messageDisplay("You lost the auction")}
        </div>
      </div>
    );
  } else if (auctionStatus == "open" && !connection) {
    return (
      <div className="auction-notification is-gray-3">
        <div className="auction-notification__show-message">
          {messageDisplay("Your connection to the server has been lost")}
        </div>
        <div className="auction-notification__card-message">
          {messageDisplay("You lost your server connection")}
        </div>
      </div>
    )
  } else if (auctionStatus == "open" && !hasActiveBid) {
    return (
      <div className="auction-notification is-warning">
        <div className="auction-notification__show-message">
          {messageDisplay("You have not bid on this auction")}
        </div>
        <div className="auction-notification__card-message">
          {messageDisplay("You have not bid yet")}
        </div>
      </div>
    );
  } else if (isBestOverallSolution) {
    return (
      <div className="auction-notification is-success">
        <div className="auction-notification__show-message">
          {messageDisplay("You have the best overall offer for this auction")}
        </div>
        <div className="auction-notification__card-message">
          {messageDisplay("You have the best overall offer")}
        </div>
      </div>
    );
  } else if (isInBestSolution) {
    return (
      <div className="auction-notification is-success">
        <div className="auction-notification__show-message">
          {messageDisplay(`You have the best overall offer for ${productNameString(bestOverallProductsForSupplier)}`)}
        </div>
        <div className="auction-notification__card-message">
          {messageDisplay(`You have the best offer for ${productPortionString(bestOverallProductsForSupplier)}`)}
        </div>
      </div>
    );
  } else if (singleSolutionIsTied && isBestSingleSolution) {
    return (
      <div className="auction-notification is-warning">
        <div className="auction-notification__show-message">
          {messageDisplay("You have the best single-supplier offer. Other suppliers have matched this offer")}
        </div>
        <div className="auction-notification__card-message">
          {messageDisplay("You have the best single-supplier offer")}
        </div>
      </div>
    );
  } else if (singleSolutionIsTied) {
    return (
      <div className="auction-notification is-warning">
        <div className="auction-notification__show-message">
          {messageDisplay("Your bid matches the best single-supplier offer, but was not the first")}
        </div>
        <div className="auction-notification__card-message">
          {messageDisplay("Your bid matches a best offer")}
        </div>
      </div>
    );
  } else if (isBestSingleSolution) {
    return(
      <div className="auction-notification is-success">
        <div className="auction-notification__show-message">
          {messageDisplay("You have the best single supplier solution")}
        </div>
        <div className="auction-notification__card-message">
          {messageDisplay("You have the best single supplier solution")}
        </div>
      </div>
    );
  } else {
    return (
      <div className="auction-notification is-danger">
        <div className="auction-notification__show-message">
          {messageDisplay("Your bid is not the best offer")}
        </div>
        <div className="auction-notification__card-message">
          {messageDisplay("Your bid is not the best offer")}
        </div>
      </div>
    );
  }
};

export default SupplierBidStatus;
