import _ from 'lodash';
import React from 'react';
import moment from 'moment';
import { formatPrice } from '../../utilities';
import SupplierBidStatus from './supplier-bid-status'
import AuctionTimeRemaining from './auction-time-remaining';

const SupplierAuctionCard = ({auctionPayload, timeRemaining, connection}) => {
  const auction = _.get(auctionPayload, 'auction');
  const auctionStatus = _.get(auctionPayload, 'status');
  const cardDateFormat = (time) => { return moment(time).format("DD MMM YYYY, k:mm"); };
  const vesselFuel = _.get(auction, 'auction_vessel_fuels.0');
  const fuel = _.get(vesselFuel, 'fuel.name');
  const fuel_quantity = _.get(vesselFuel, 'quantity');
  const vessel = _.get(vesselFuel, 'vessel.name');


  const bidStatusDisplay = () => {
    const lowestBid = _.chain(auctionPayload)
      .get('lowest_bids')
      .first()
      .value();
    if (lowestBid && auctionStatus != 'pending') {
      return (
        <div>
          <div className="card-content__bid-status">
            <SupplierBidStatus auctionPayload={auctionPayload} connection={connection} />
            <div className="card-content__best-price">
              <strong>Best Offer: </strong>{lowestBid.amount == null ? <i>(None)</i> : `$` + formatPrice(lowestBid.amount)}
            </div>
          </div>
{/*
          <div className="card-content__bid">
            <div className="card-content__bid__title has-padding-right-xs">
              <div>Place Bid</div>
              <span className="icon is-inline-block has-text-dark has-margin-left-md"><i className="fas fa-plus"></i></span>
            </div>
          </div>
*/}
        </div>
      );
    } else {
      return "";
    }
  }

  return (
    <div className="column is-one-third-desktop is-half-tablet">
      <div className={`card card--auction qa-auction-${auction.id}`}>
        <div className="card-content qa-auction-supplier-card">
          <div className="is-clearfix is-flex">
            {/* Start Status/Time Bubble */}
            <div className={`auction-card__status auction-card__status--${auctionStatus}`}>
              <span className="qa-auction-status">{auctionStatus}</span>
              <AuctionTimeRemaining auctionPayload={auctionPayload} auctionTimer={timeRemaining} />
            </div>
            {/* End Status/Time Bubble */}
            {/* Start Link to Auction */}
              <a href={`/auctions/${auction.id}`} action-label="Go To Auction" className="auction-card__link-to-auction"><span className="icon is-medium has-text-right"><i className="fas fa-2x fa-angle-right"></i></span></a>
            {/* End Link to Auction */}
          </div>
        </div>
        <div className="card-title">
          <h3 className="title is-size-4 has-text-weight-bold is-marginless">
            {vessel}
            {auction.is_traded_bid_allowed && <span> <i action-label="Traded Bids Accepted" className="fas fa-exchange-alt has-text-gray-3 card__traded-bid-marker"></i> </span>}
          </h3>
          <p className="has-family-header has-margin-bottom-xs">{auction.buyer.name}</p>
          <p className="has-family-header"><span className="has-text-weight-bold">{auction.port.name}</span> (<strong>ETA</strong> {cardDateFormat(auction.eta)}<span className="is-hidden-mobile"> &ndash; <strong>ETD</strong> {cardDateFormat(auction.etd)}</span>)</p>
        </div>
        <div className="card-content__products">
          {fuel} ({auction.fuel_quantity}&nbsp;MT)
        </div>

        {/* <div>
          <div className="card-content__auction-status has-margin-top-md">
            <div>Respond to Invitation</div>
            <div className="field has-addons qa-auction-invitation-controls">
              <div className="control">
                <a className="button is-small is-success">
                  <span>Accept</span>
                </a>
              </div>
              <div className="control">
                <a className="button is-small is-danger">
                  <span>Decline</span>
                </a>
              </div>
              <div className="control">
                <a className="button is-small is-gray-3">
                  <span>Maybe</span>
                </a>
              </div>
            </div>
          </div>
        </div> */}
        { bidStatusDisplay() }
      </div>
    </div>
  );
}

export default SupplierAuctionCard;
