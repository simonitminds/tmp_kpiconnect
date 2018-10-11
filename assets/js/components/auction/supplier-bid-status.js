import React from 'react';
import _ from 'lodash';
import { quickOrdinal } from '../../utilities';

const SupplierBidStatus = ({auctionPayload, connection, supplierId}) => {
  const supplierIdInt = parseInt(supplierId);
  const bidList = _.get(auctionPayload, 'bid_history', []);

  const bestSingleSolutionPrice = _.get(auctionPayload, 'solutions.best_single_supplier.normalized_price')
  const bestSingleSolutionBids = _.get(auctionPayload, 'solutions.best_single_supplier.bids');
  const bestSingleSolutionSupplierIds = _.map(bestSingleSolutionBids, 'supplier_id');
  const isBestSingleSolution = _.includes(bestSingleSolutionSupplierIds, supplierIdInt);

  const bestOverallSolutionPrice = _.get(auctionPayload, 'solutions.best_overall.normalized_price')
  const bestOverallSolutionBids = _.get(auctionPayload, 'solutions.best_overall.bids');
  const bestSolutionSupplierIds = _.map(bestOverallSolutionBids, 'supplier_id');
  const isInBestSolution = _.includes(bestSolutionSupplierIds, supplierIdInt);

  const winningSolutionBids = _.get(auctionPayload, "solutions.winning_solution.bids");
  const winningSolutionSupplierIds = _.map(winningSolutionBids, 'supplier_id');
  const isInWinningSolution = _.includes(winningSolutionSupplierIds, supplierIdInt);

  const solutionIsTied = bestSingleSolutionPrice == bestOverallSolutionPrice && !isBestSingleSolution
  const auctionStatus = _.get(auctionPayload, 'status');

  const messageDisplay = (message) => {
    return (
      <h3 className="has-text-weight-bold has-margin-bottom-none">
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
      <div className="auction-notification box is-gray-3" >
        {messageDisplay("No offer was selected")}
      </div>
    );
  } else if (auctionStatus == "closed" && isInWinningSolution) {
    return (
      <div className="auction-notification box is-success" >
        {messageDisplay("You won the auction")}
      </div>
    );
  } else if (auctionStatus == "closed" && !isInWinningSolution) {
    return (
      <div className="auction-notification box is-danger" >
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
      <div className="auction-notification box is-gray-2" >
        {messageDisplay("Your connection to the server has been lost")}
      </div>
    )
  } else if (bidList.length == 0) {
    return (
      <div className="auction-notification box is-warning" >
        {messageDisplay("You have not bid on this auction")}
      </div>
    );
  } else if (solutionIsTied) {
    return (
      <div className="auction-notification box is-warning" >
        {messageDisplay("Your bid matches the best offer")}
      </div>
    );
  } else if (isInBestSolution && isBestSingleSolution) {
    return (
      <div className="auction-notification box is-success">
        {messageDisplay("Your bid is the best overall offer")}
      </div>
    );
  } else if (isInBestSolution) {
    return (
      <div className="auction-notification box is-success" >
        {messageDisplay("Your bid is part of the best overall offer")}
      </div>
    );
  } else if (isBestSingleSolution){
    return(
      <div className="auction-notification box is-warning">
        {messageDisplay("Your bid is the best single supplier solution")}
      </div>
    );
  } else {
    return (
      <div className="auction-notification box is-danger" >
        {messageDisplay("Your bid is not the best offer")}
      </div>
    );
  }
};

export default SupplierBidStatus;
