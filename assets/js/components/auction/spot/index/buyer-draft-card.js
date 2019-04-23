import _ from 'lodash';
import React from 'react';
import moment from 'moment';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { cardDateFormat, etaAndEtdForAuction, formatPrice } from '../../../../utilities';
import SupplierBidStatus from '../show/supplier-bid-status';
import AuctionTimeRemaining from '../../common/auction-time-remaining';
import AuctionTitle from '../../common/auction-title';
import FuelPriceDisplay from '../../common/index/fuel-price-display';

const BuyerDraftCard = ({auctionPayload, timeRemaining}) => {
  const auction = _.get(auctionPayload, 'auction');
  const auctionType = _.get(auction, 'type');
  const vessels = _.get(auction, 'vessels');
  const { eta, etd } = etaAndEtdForAuction(auction);
  const fuels = _.get(auction, 'fuels');
  const vesselFuels = _.get(auction, 'auction_vessel_fuels');
  const auctionStatus = _.get(auctionPayload, 'status');

  const confirmCancellation = (e) => { event.preventDefault();
                                       return confirm('Are you sure you want to cancel this auction?') ? window.location = `/auctions/${auction.id}/cancel` : false; };

  const uniqueFuels = _.chain(vesselFuels)
    .map((vf) => vf.fuel)
    .filter()
    .uniqBy('id')
    .value();

  const fuelQuantities = _.chain(uniqueFuels)
      .reduce((acc, fuel) => {
        acc[fuel.id] = _.chain(vesselFuels)
          .filter((vf) => vf.fuel_id == fuel.id)
          .sumBy((vf) => vf.quantity)
          .value();
        return acc;
      }, {})
      .value();

  const fuelForVesselFuels = _.chain(vesselFuels)
    .reduce((acc, vf) => {
      acc[vf.id] = vf.fuel_id;
      return acc;
    }, {})
    .value();

  const products = _.map(uniqueFuels, (fuel) => {
    return {fuel: fuel, quantity: fuelQuantities[fuel.id]};
  });

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
          <p className="has-family-header"><span className="has-text-weight-bold">{auction.port.name}</span> (<strong>ETA</strong> {cardDateFormat(eta)}<span className="is-hidden-mobile"> &ndash; <strong>ETD</strong> {cardDateFormat(etd)}</span>)</p>
        </div>
        <div className="card-content__products">
          <span className="card-content__product-header">Products</span>
          <FuelPriceDisplay products={products} auctionType={auctionType} auctionStatus={auctionStatus} />
        </div>
      </div>
    </div>
  );
}

export default BuyerDraftCard;
