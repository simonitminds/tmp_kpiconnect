import React from 'react';
import _ from 'lodash';
import { quickOrdinal } from '../../../../utilities';

const SupplierBidStatus = ({auctionPayload, connection, supplierId}) => {
  const supplierIdInt = parseInt(supplierId);
  const bidList = _.get(auctionPayload, 'bid_history', []);
  const hasActiveBid = (_.filter(bidList, 'active').length > 0);

  const suppliersBestSolution = _.get(auctionPayload, 'solutions.suppliers_best_solution');
  const bestSingleSolution = _.get(auctionPayload, 'solutions.best_single_supplier');

  const bestOverallSolution = _.get(auctionPayload, 'solutions.best_overall');
  console.log(bestOverallSolution);
  const bestOverallSolutionBids = _.get(bestOverallSolution, 'bids');

  const bestSolutionSupplierIds = _.map(bestOverallSolutionBids, 'supplier_id');
  const isInBestSolution = _.includes(bestSolutionSupplierIds, supplierIdInt);
  const isBestOverallSolution = !_.some(bestSolutionSupplierIds, (id) => id != supplierIdInt);

  const winningSolutionBids = _.get(auctionPayload, "solutions.winning_solution.bids");
  const winningSolutionSupplierIds = _.map(winningSolutionBids, 'supplier_id');
  const isInWinningSolution = _.includes(winningSolutionSupplierIds, supplierIdInt);
  const isWinningSolution = !_.some(winningSolutionSupplierIds, (id) => id != supplierIdInt);

  const auctionStatus = _.get(auctionPayload, 'status');

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
  } else if (isBestOverallSolution && bestOverallSolution) {
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
