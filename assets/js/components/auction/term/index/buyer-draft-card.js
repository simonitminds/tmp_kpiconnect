import _ from 'lodash';
import React from 'react';
import moment from 'moment';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { cardDateFormat, etaAndEtdForAuction, formatPrice, formatMonthYear } from '../../../../utilities';
import AuctionTimeRemaining from '../../common/auction-time-remaining';
import AuctionTitle from '../../common/auction-title';
import FuelPriceDisplay from '../../common/index/fuel-price-display';

const BuyerDraftCard = ({auctionPayload, timeRemaining}) => {
  const auction = _.get(auctionPayload, 'auction');
  const auctionType = _.get(auction, 'type')
  const vessels = _.get(auction, 'vessels');
  const startDate = _.get(auction, 'start_date');
  const endDate = _.get(auction, 'end_date');
  const fuel = _.get(auction, 'fuel');
  const fuelIndex = _.get(auction, 'fuel_index');
  const fuelQuantity = _.get(auction, 'fuel_quantity');
  const auctionStatus = _.get(auctionPayload, 'status');

  const vesselNameDisplay = _.chain(vessels).map('name').join(", ").value();
  const products = [{fuel: fuel, quantity: fuelQuantity}];

  return (
    <div className="column is-one-third-desktop is-half-tablet">
      <div className={`card card--auction card--draft qa-auction-${auction.id}`}>
        <div className="card-content qa-auction-buyer-card">
          <div className="is-clearfix is-flex">
            {/* Start Status/Time Bubble */}
            <div className={`auction-status auction-status--${auctionStatus}`}>
              <span className="qa-auction-status">{auctionStatus}</span>
              <AuctionTimeRemaining auctionPayload={auctionPayload} auctionTimer={timeRemaining} />
            </div>
            {/* End Status/Time Bubble */}
            {/* Start Link to Auction Edit/Delete */}
            <div className="auction-card__buttons">
              <a href={`/auctions/${auction.id}/edit`} action-label="Edit Auction" className="auction-card__link-to-auction-edit is-hidden-420">
                <span className="icon is-medium has-text-right">
                  <FontAwesomeIcon icon="edit" size="lg" />
                </span>
              </a>
              {/* End Link to Auction Edit/Delete */}
              {/* Start Link to Auction */}
                <a href={`/auctions/${auction.id}`} action-label="Go To Auction" className="auction-card__link-to-auction"><span className="icon is-medium has-text-right"><FontAwesomeIcon icon="angle-right" size="2x" /></span></a>
              {/* End Link to Auction */}
            </div>
          </div>
        </div>
        <div className="card-title">
          <h3 className="title is-size-4 has-text-weight-bold is-marginless">
            <AuctionTitle auction={auction} />
          </h3>
          <p className="has-family-header has-margin-bottom-xs">{auction.buyer.name}</p>
          <p className="has-family-header"><span className="has-text-weight-bold">{vesselNameDisplay}</span> ({formatMonthYear(startDate)}<span className="is-hidden-mobile"> &ndash; {formatMonthYear(endDate)}</span>)</p>
          {auctionType == "formula_related" ?
            <p className="has-family-header"><span className="has-text-weight-bold">Index</span> <span className="is-hidden-mobile">{fuelIndex ? fuelIndex.name : "—"}</span></p> :
            ""
          }
        </div>
        <div className="card-content__products">
          <span className="card-content__product-header">Products <span className={`qa-auction-${auctionType}`}>({_.startCase(auctionType)})</span></span>
          <FuelPriceDisplay products={products} auctionType={auctionType} auctionStatus={auctionStatus} />
        </div>
      </div>
    </div>
  );
};

export default BuyerDraftCard;
