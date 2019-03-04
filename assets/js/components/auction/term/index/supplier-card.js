import _ from 'lodash';
import React from 'react';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import moment from 'moment';
import { cardDateFormat, etaAndEtdForAuction, formatPrice, formatMonthYear } from '../../../../utilities';
import SupplierBidStatus from '../show/supplier-bid-status'
import AuctionTimeRemaining from '../../common/auction-time-remaining';
import AuctionInvitation from '../../common/auction-invitation';
import AuctionTitle from '../../common/auction-title';
import FuelPriceDisplay from '../../common/index/fuel-price-display';

const SupplierCard = ({auctionPayload, timeRemaining, connection, currentUserCompanyId}) => {
  const auction = _.get(auctionPayload, 'auction');
  const auctionType = _.get(auction, 'type');
  const auctionStatus = _.get(auctionPayload, 'status');
  const startDate = _.get(auction, 'start_date');
  const endDate = _.get(auction, 'end_date');
  const vessels = _.get(auction, 'vessels');
  const fuel = _.get(auction, 'fuel');
  const fuelQuantity = _.get(auction, 'fuel_quantity');
  const bestSolution = _.get(auctionPayload, 'solutions.best_overall');
  const winningSolution = _.get(auctionPayload, 'solutions.winning_solution');

  const bidStatusDisplay = () => {
    const lowestBid = _.chain(auctionPayload)
      .get('solutions.best_overall')
      .value();

    if (lowestBid && auctionStatus != 'pending') {
      return (
        <div>
          <div className="card-content__bid-status">
            <SupplierBidStatus auctionPayload={auctionPayload} connection={connection} supplierId={currentUserCompanyId} />
          </div>
        </div>
      );
    } else if (auctionStatus == 'pending') {
      return <AuctionInvitation auctionPayload={auctionPayload} supplierId={currentUserCompanyId}/>;
    } else {
      return "";
    }
  }

  const vesselNameDisplay = _.chain(vessels).map('name').join(", ").value();

  const solution = auctionStatus == 'closed' ? winningSolution : bestSolution;
  const products = [{fuel: fuel, quantity: fuelQuantity, bid: solution && solution.bids[fuel.id]}];

  return (
    <div className="column is-one-third-desktop is-half-tablet">
      <div className={`card card--auction qa-auction-${auction.id}`}>
        <div className="card-content qa-auction-supplier-card">
          <div className="is-clearfix is-flex">
            {/* Start Status/Time Bubble */}
            <div className={`auction-status auction-status--${auctionStatus}`}>
              <span className="qa-auction-status">{auctionStatus}</span>
              <AuctionTimeRemaining auctionPayload={auctionPayload} auctionTimer={timeRemaining} />
            </div>
            {/* End Status/Time Bubble */}
            {/* Start Link to Auction */}
              <a href={`/auctions/${auction.id}`} action-label="Go To Auction" className="auction-card__link-to-auction"><span className="icon is-medium has-text-right"><FontAwesomeIcon icon="angle-right" size="2x" /></span></a>
            {/* End Link to Auction */}
          </div>
        </div>
        <div className="card-title">
          <h3 className="title is-size-4 has-text-weight-bold is-marginless">
            <AuctionTitle auction={auction} />
          </h3>
          <p className="has-family-header has-margin-bottom-xs">{auction.buyer.name}</p>
          <p className="has-family-header"><span className="has-text-weight-bold">{vesselNameDisplay}</span> ({formatMonthYear(startDate)}<span className="is-hidden-mobile"> &ndash; {formatMonthYear(endDate)}</span>)</p>
        </div>
        <div className="card-content__products">
          <span className="card-content__product-header">{auctionStatus == 'closed' ? 'Winning' : 'Leading Offer'} Prices <span className={`qa-auction-${auctionType}`}>({_.startCase(auctionType)})</span></span>
          <FuelPriceDisplay products={products} auctionType={auctionType} />
        </div>
        { bidStatusDisplay() }
      </div>
    </div>
  );
}

export default SupplierCard;
