import _ from 'lodash';
import React from 'react';
import moment from 'moment';
import { formatTimeRemaining, formatTimeRemainingColor, formatPrice } from '../../utilities';
import SupplierBidStatus from './supplier-bid-status'

const SupplierAuctionCard = ({auctionPayload, timeRemaining}) => {
  const auction = _.get(auctionPayload, 'auction');
  const auctionStatus = _.get(auctionPayload, 'state.status');
  const cardDateFormat = (time) => { return moment(time).format("DD MMM YYYY, k:mm"); };

  const bidStatusDisplay = () => {
    const lowestBid = _.get(auction, 'state.lowest_bids');
    if (lowestBid && auctionStatus != 'pending') {
      return (
        <div>
          <div className="card-content__bid-status">
            <SupplierBidStatus auctionPayload={auctionPayload} />
            { auctionStatus != 'pending' ?
              <div className="card-content__best-price"><strong>Best Offer: </strong>{lowestBid.amount == null ? <i>(None)</i> : `$` + formatPrice(lowestBid.amount)}</div>
              :
              ''
            }
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

  const AuctionTimeRemaining = (auctionTimer) => {
    if (auctionStatus == "open" || auctionStatus == "decision") {
      return (
        <span className={`auction-card__time-remaining auction-card__time-remaining--${formatTimeRemainingColor(auctionStatus, auctionTimer)}`}>
          <span className="icon has-margin-right-xs"><i className="far fa-clock"></i></span>
          <span
            className="qa-auction-time_remaining"
            id="time-remaining"
          >
            {formatTimeRemaining(auctionStatus, auctionTimer, "index")}
          </span>
        </span>
      );
    }
    else {
      return (
        <span className={`auction-card__time-remaining auction-card__time-remaining--${formatTimeRemainingColor(auctionStatus, auctionTimer)}`}>
          <span className="icon has-margin-right-xs"><i className="far fa-clock"></i></span>
          {cardDateFormat(_.get(auctionPayload, 'auction.auction_start'))}
        </span>
      );
    }
  }

  return (
    <div className="column is-one-third">
      <div className={`card qa-auction-${auction.id}`}>
        <div className="card-content">
          <div className="is-clearfix">
            {/* Start Status/Time Bubble */}
            <div className={`auction-card__status auction-card__status--${auctionStatus}`}>
              <span className="qa-auction-status">{auctionStatus}</span>
              {AuctionTimeRemaining(timeRemaining)}
            </div>
            {/* End Status/Time Bubble */}
            {/* Start Link to Auction */}
              <a href={`/auctions/${auction.id}`} className="auction-card__link-to-auction"><span className="icon is-medium has-text-right"><i className="fas fa-2x fa-angle-right"></i></span></a>
            {/* End Link to Auction */}
          </div>
        </div>
        <div className="card-title">
          <h3 className="title is-size-4 has-text-weight-bold is-marginless">{auction.vessel.name}</h3>
          <p className="has-family-header has-margin-bottom-xs">{auction.buyer.name}</p>
          <p className="has-family-header"><span className="has-text-weight-bold">{auction.port.name}</span> (<strong>ETA</strong> {cardDateFormat(auction.eta)} &ndash; <strong>ETD</strong> {cardDateFormat(auction.etd)})</p>
        </div>
        <div className="card-content__products">
          {auction.fuel.name} ({auction.fuel_quantity}&nbsp;MT)
        </div>

        <div>
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
        </div>
        { bidStatusDisplay() }
      </div>
    </div>
  );
}

export default SupplierAuctionCard;