import _ from 'lodash';
import React from 'react';
import moment from 'moment';
import { formatTimeRemaining, formatTimeRemainingColor } from '../../utilities';
import SupplierBidStatus from './SupplierBidStatus'

const AuctionCard = ({auction, timeRemaining, currentUserIsBuyer}) => {
  const cardDateFormat = (time) => { return moment(time).format("DD MMM YYYY, k:mm"); };
  const bidStatusDisplay = () => {
    let winningBid;
    if (currentUserIsBuyer) {
      winningBid = _.chain(auction).get('state.winning_bid').first().value();
      const winningBidCount = _.get(auction, 'state.winning_bid.length');
      return (
        <div className="card-content__bid-status">
          <div className="card-content__best-bidder">
            {winningBid ? winningBid.supplier : `No bids yet` }
            Lowest Bidder: {winningBid.supplier}{winningBidCount > 1 ? ` (of ${winningBidCount})` : ""}
          </div>
          <div className="card-content__best-price"><strong>Best Offer: </strong>${winningBid.amount}</div>
        </div>
      );
    } else {
      winningBid = _.get(auction, 'state.winning_bid');
      if (winningBid) {
        return (
          <div>
            <div className="card-content__bid-status">
              <SupplierBidStatus auction={auction} />
              <div className="card-content__best-price"><strong>Best Offer: </strong>${winningBid.amount}</div>
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
  }

  function AuctionTimeRemaining(auction, timeRemaining) {
    const auctionStatus = auction.state.status;
    const auctionTimer = timeRemaining[auction.id];
    if (auctionStatus == "open" || auctionStatus == "decision") {
      return (
        <span className={`auction-card__time-remaining auction-card__time-remaining--${formatTimeRemainingColor(auction, auctionTimer)}`}>
          <span className="icon has-margin-right-xs"><i className="far fa-clock"></i></span>
          <span
            className="qa-auction-time_remaining"
            id="time-remaining"
          >
            {formatTimeRemaining(auction, auctionTimer, "index")}
          </span>
        </span>
      );
    }
    else {
      return (
        <span className={`auction-card__time-remaining auction-card__time-remaining--${formatTimeRemainingColor(auction, auctionTimer)}`}>
          <span className="icon has-margin-right-xs"><i className="far fa-clock"></i></span>
          {cardDateFormat(auction.auction_start)}
        </span>
      );
    }
  };
  return (
    <div className="column is-one-third">
      <div className={`card qa-auction-${auction.id}`}>
        <div className="card-content">
          <div className="is-clearfix">
            {/* Start Status/Time Bubble */}
            <div className={`auction-card__status auction-card__status--${auction.state.status}`}>
              <span className="qa-auction-status">{auction.state.status}</span>
              {AuctionTimeRemaining(auction, timeRemaining)}
            </div>
            {/* End Status/Time Bubble */}
            {/* Start Link to Auction */}
              <a href={`/auctions/${auction.id}`} className="auction-card__link-to-auction"><span className="icon is-medium has-text-right"><i className="fas fa-2x fa-angle-right"></i></span></a>
            {/* End Link to Auction */}
            {/* Start Link to Auction Edit */}
              { currentUserIsBuyer ?
                <a href={`/auctions/${auction.id}/edit`} className="auction-card__link-to-auction-edit">
                  <span className="icon is-medium has-text-right">
                    <i className="fas fa-lg fa-edit"></i>
                  </span>
                </a> : ""}
            {/* End Link to Auction Edit */}
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
      { currentUserIsBuyer && auction.state.status == 'pending' ?
        <div className="card-content__products">
          <a href={`/auctions/start/${auction.id}`} className="card__start-auction button is-link is-small qa-auction-start"><span className="icon"><i className="fas fa-play"></i></span> Start Auction</a>
        </div>
        :
        <div className="is-none"></div>
      }

      { currentUserIsBuyer ?
        <div>
          <div className="card-content__auction-status has-margin-top-md">
            <div>Suppliers Participating</div>
            <div className="card-content__rsvp qa-auction-suppliers">
              <span className="icon has-text-success has-margin-right-xs"><i className="fas fa-check-circle"></i></span>{auction.suppliers.length}&nbsp;
              <span className="icon has-text-warning has-margin-right-xs"><i className="fas fa-adjust"></i></span>0&nbsp;
              <span className="icon has-text-danger has-margin-right-xs"><i className="fas fa-times-circle"></i></span>0&nbsp;
              <span className="icon has-text-dark has-margin-right-xs"><i className="fas fa-question-circle"></i></span>0&nbsp;
            </div>
          </div>
          {/* <div className="card-content__auction-status">
              <div>Are you ready to post your auction?</div>
              <button className="button is-primary">Schedule Auction</button>
          </div> */}
        </div>
      :
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
      }

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

export default AuctionCard;
