import _ from 'lodash';
import React from 'react';
import moment from 'moment';
import { formatPrice } from '../../utilities';
import SupplierBidStatus from './supplier-bid-status';
import AuctionTimeRemaining from './auction-time-remaining';

const BuyerAuctionCard = ({auctionPayload, timeRemaining}) => {
  const fuel = _.get(auction, 'fuel.name');
  const auction = _.get(auctionPayload, 'auction');
  const auctionStatus = _.get(auctionPayload, 'state.status');
  const cardDateFormat = (time) => { return moment(time).format("DD MMM YYYY, k:mm"); };
  const lowestBid = _.chain(auctionPayload).get('state.lowest_bids').first().value();
  const lowestBidCount = _.get(auctionPayload, 'state.lowest_bids.length');

  const lowestBidMessage = () => {
    if (lowestBid && lowestBidCount == 1) {
      return (
        <div className="card-content__best-bidder">
          <span className="card-content__best-bidder__name">Lowest Bid: {lowestBid.supplier}</span>
        </div>
      )
    } else if (lowestBid && lowestBidCount > 1) {
      return (
        <div className="card-content__best-bidder">
          <span className="card-content__best-bidder__name">Lowest Bid: {lowestBid.supplier}</span><span className="card-content__best-bidder__count">(of {lowestBidCount})</span>
        </div>
      )
    } else {
      return (
        <div className="card-content__best-bidder">
          Lowest Bid: <i>No bids yet</i>
        </div>
      )
    }
  }

  const bidStatusDisplay = () => {
    if (lowestBidCount > 0) {
      return (
        <div className="card-content__bid-status">
          {lowestBidMessage()}
          { auctionStatus != 'pending' ?
            <div className="card-content__best-price"><strong>Best Offer: </strong>{lowestBid.amount == null ? <i>(None)</i> : `$` + formatPrice(lowestBid.amount)}</div>
            :
            ''
          }
        </div>
      );
    } else {
      return "";
    }
  }

  return (
    <div className="column is-one-third">
      <div className={`card card--auction ${auctionStatus == 'draft' ? 'card--draft' : ''} qa-auction-${auction.id}`}>
        <div className="card-content">
          <div className="is-clearfix">
            {/* Start Status/Time Bubble */}
            <div className={`auction-card__status auction-card__status--${auctionStatus}`}>
              <span className="qa-auction-status">{auctionStatus}</span>
              <AuctionTimeRemaining auctionPayload={auctionPayload} auctionTimer={timeRemaining} />
            </div>
            {/* End Status/Time Bubble */}
            {/* Start Link to Auction */}
              <a href={`/auctions/${auction.id}`} className="auction-card__link-to-auction"><span className="icon is-medium has-text-right"><i className="fas fa-2x fa-angle-right"></i></span></a>
            {/* End Link to Auction */}
            {/* Start Link to Auction Edit */}
              <a href={`/auctions/${auction.id}/edit`} className="auction-card__link-to-auction-edit">
                <span className="icon is-medium has-text-right">
                  <i className="fas fa-lg fa-edit"></i>
                </span>
              </a>
            {/* End Link to Auction Edit */}
          </div>
        </div>
        <div className="card-title">
          <h3 className="title is-size-4 has-text-weight-bold is-marginless">{auction.vessel.name}</h3>
          <p className="has-family-header has-margin-bottom-xs">{auction.buyer.name}</p>
          <p className="has-family-header"><span className="has-text-weight-bold">{auction.port.name}</span> (<strong>ETA</strong> {cardDateFormat(auction.eta)} &ndash; <strong>ETD</strong> {cardDateFormat(auction.etd)})</p>
        </div>
        {fuel != null ?
          <div className="card-content__products">
            {fuel} ({auction.fuel_quantity}&nbsp;MT)
          </div>
          :
          <div className="is-none"></div>
        }
        { auctionStatus == 'pending' ?
          <div className="card-content__products">
            <a href={`/auctions/${auction.id}/start`} className="card__start-auction button is-link is-small qa-auction-start">
              <span className="icon"><i className="fas fa-play"></i></span> Start Auction
            </a>
          </div>
          :
          <div className="is-none"></div>
        }

        <div>
          {auctionStatus == 'pending' || auctionStatus == 'open' ?
            <div className="card-content__auction-status has-margin-top-md">
              <div>Suppliers Participating</div>
              <div className="card-content__rsvp qa-auction-suppliers">
                <span className="icon has-text-success has-margin-right-xs"><i className="fas fa-check-circle"></i></span>{auction.suppliers.length}&nbsp;
                <span className="icon has-text-warning has-margin-right-xs"><i className="fas fa-adjust"></i></span>0&nbsp;
                <span className="icon has-text-danger has-margin-right-xs"><i className="fas fa-times-circle"></i></span>0&nbsp;
                <span className="icon has-text-dark has-margin-right-xs"><i className="fas fa-question-circle"></i></span>0&nbsp;
              </div>
            </div>
            :
            <div className="is-none"></div>
          }
          {/* <div className="card-content__auction-status">
              <div>Are you ready to post your auction?</div>
              <button className="button is-primary">Schedule Auction</button>
          </div> */}
        </div>
        { bidStatusDisplay() }
    {/* ADMIN ONLY */}
        {/* <div className="card-content__bid-status">
          <div className="card-content__best-bidder">Lowest Bidder [Supplier(s)]</div>
          <div className="card-content__best-price"><strong>Their Offer: </strong>PRICE</div>
        </div>
        <div className="card-content__bid">
          <div className="card-content__bid__title has-padding-right-xs">
            <div>Place Bid</div>
            <span className="icon is-inline-block has-text-dark has-margin-left-md"><i className="fas fa-plus"></i></span>
          </div>
        </div>
        <div className="card-content__bid">
          <div className="card-content__bid__title">
            <div>Change RSVP</div>
            <div className="card-content__change-rsvp">
              <div className="card-content__rsvp">
                <span className="icon has-text-success has-margin-right-xs"><i className="fas fa-check-circle"></i></span>0&nbsp;
                <span className="icon has-text-warning has-margin-right-xs"><i className="fas fa-adjust"></i></span>0&nbsp;
                <span className="icon has-text-danger has-margin-right-xs"><i className="fas fa-times-circle"></i></span>0&nbsp;
                <span className="icon has-text-dark has-margin-right-xs"><i className="fas fa-question-circle"></i></span>0&nbsp;
              </div>
              <span className="icon is-inline-block has-text-dark has-margin-left-md"><i className="fas fa-plus"></i></span>
            </div>
          </div>
        </div> */}
    {/* / ADMIN ONLY */}
      </div>
    </div>
  );
}

export default BuyerAuctionCard;
