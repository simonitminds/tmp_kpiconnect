import _ from 'lodash';
import React from 'react';
import moment from 'moment';
import { formatPrice } from '../../utilities';
import SupplierBidStatus from './supplier-bid-status';
import AuctionTimeRemaining from './auction-time-remaining';

const BuyerAuctionCard = ({auctionPayload, timeRemaining}) => {
  const auction = _.get(auctionPayload, 'auction');
  const vessels = _.get(auction, 'vessels');
  const fuels = _.get(auction, 'fuels');
  const vesselFuels = _.get(auction, 'auction_vessel_fuels');
  const auctionStatus = _.get(auctionPayload, 'status');
  const cardDateFormat = (time) => { return moment(time).format("DD MMM YYYY, k:mm"); };
  const bestSolution = _.get(auctionPayload, 'solutions.best_overall');
  const winningSolution = _.get(auctionPayload, 'solutions.winning_solution');

  const confirmCancellation = () => { return confirm('Are you sure you want to cancel this auction?') ? window.open(`/auctions/${auction.id}/cancel`) : false; };

  const lowestBidMessage = () => {
    if (winningSolution) {
      return (
        <div className="card-content__best-bidder card-content__best-bidder--winner">
          <div className="card-content__best-bidder__name">Winner: {winningSolution.supplier}</div>
        </div>
      )
    } else if (auctionStatus == 'expired') {
      return (
        <div className="card-content__best-bidder">
          <div className="card-content__best-bidder__name">No offer was selected</div>
        </div>
      )
    } else if (bestSolution) {

      const suppliers = _.map(bestSolution.bids, "supplier");
      return (
        <div className="card-content__best-bidder">
          <div className="card-content__best-bidder__name">Best Solution: {suppliers[0]}</div><div className="card-content__best-bidder__count">(+{suppliers.length - 1})</div>
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
    if (auctionStatus != 'pending' && bestSolution) {
      return (
        <div className="card-content__bid-status">
          {lowestBidMessage()}
          <div className="card-content__best-price"><strong>{ auctionStatus == 'closed' ? '' : 'Best'} Offer: </strong>{bestSolution.normalized_price == null ? <i>(None)</i> : `$` + formatPrice(bestSolution.normalized_price)}</div>
        </div>
      );
    } else {
      return "";
    }
  }

  const vesselNameDisplay = (vesselFuels) => {
    const vesselNames = _.chain(vesselFuels)
      .map((vf) => vf.vessel)
      .filter()
      .uniqBy('id')
      .map("name")
      .value();

    return vesselNames.join(", ");
  };

  const fuelDisplay = (vesselFuels) => {
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

    return _.map(uniqueFuels, (fuel) => {
      return(
        <div className="card-content__product" key={fuel.id}>
          {fuel.name} { fuelQuantities[fuel.id] ?
            <span className="fuel-amount">({fuelQuantities[fuel.id]}&nbsp;MT)</span>
            : <span className="no-amount">(no amount given)</span>
          }
        </div>
      );
    });
  };

  return (
    <div className="column is-one-third-desktop is-half-tablet">
      <div className={`card card--auction ${auctionStatus == 'draft' ? 'card--draft' : ''} qa-auction-${auction.id}`}>
        <div className="card-content qa-auction-buyer-card">
          <div className="is-clearfix is-flex">
            {/* Start Status/Time Bubble */}
            <div className={`auction-card__status auction-card__status--${auctionStatus}`}>
              <span className="qa-auction-status">{auctionStatus}</span>
              <AuctionTimeRemaining auctionPayload={auctionPayload} auctionTimer={timeRemaining} />
            </div>
            {/* End Status/Time Bubble */}
            {/* Start Link to Auction Edit/Delete */}
            { auctionStatus == 'draft' || auctionStatus == 'pending' ?
              <div>
                <a href={`/auctions/${auction.id}/edit`} action-label="Edit Auction" className="auction-card__link-to-auction-edit is-hidden-420">
                  <span className="icon is-medium has-text-right">
                    <i className="fas fa-lg fa-edit"></i>
                  </span>
                </a>
                {auctionStatus != 'canceled' ?
                 <a id="cancel-auction" href="" onClick={() => confirmCancellation()} action-label="Cancel Auction" className="auction-card__link-to-auction-cancel is-hidden-420 qa-auction-cancel">
                  <span className="icon is-medium has-text-right">
                    <i className="fas fa-lg fa-times"></i>
                  </span>
                  </a>
                  :
                  <span></span>
                }
              </div>
              :
              <div></div>
            }
            {/* End Link to Auction Edit/Delete */}
            {/* Start Link to Auction */}
              <a href={`/auctions/${auction.id}`} action-label="Go To Auction" className="auction-card__link-to-auction"><span className="icon is-medium has-text-right"><i className="fas fa-2x fa-angle-right"></i></span></a>
            {/* End Link to Auction */}
          </div>
        </div>
        <div className="card-title">
          <h3 className="title is-size-4 has-text-weight-bold is-marginless">
            { vesselNameDisplay(vesselFuels) }
            {auction.is_traded_bid_allowed && <span> <i action-label="Traded Bids Accepted" className="fas fa-exchange-alt has-text-gray-3 card__traded-bid-marker"></i> </span>}
          </h3>
          <p className="has-family-header has-margin-bottom-xs">{auction.buyer.name}</p>
          <p className="has-family-header"><span className="has-text-weight-bold">{auction.port.name}</span> (<strong>ETA</strong> {cardDateFormat(auction.eta)}<span className="is-hidden-mobile"> &ndash; <strong>ETD</strong> {cardDateFormat(auction.etd)}</span>)</p>
        </div>
        <div className="card-content__products">
          { fuelDisplay(vesselFuels) }
        </div>
        { auctionStatus == 'pending' ?
          <div className="card-content__products">
            {/* <a href={`/auctions/${auction.id}/cancel`} className="card__cancel-auction button is-danger is-small qa-auction-cancel">
              <span className="icon is-inline-block has-margin-right-xs"><i className="fas fa-times"></i></span> Cancel Auction
            </a> */}
          { window.isAdmin &&
            <a href={`/auctions/${auction.id}/start`} className="card__start-auction button is-link is-small qa-auction-start">
              <span className="icon"><i className="fas fa-play"></i></span> Start Auction
            </a>
          }
          </div>
          :
          <div className="is-none"></div>
        }

        <div>
          {auctionStatus == 'pending' || auctionStatus == 'open' ?
            // <div className="card-content__auction-status has-margin-top-md">
            //   <div>Suppliers Participating</div>
            //   <div className="card-content__rsvp qa-auction-suppliers">
            //     <span className="icon has-text-success has-margin-right-xs"><i className="fas fa-check-circle"></i></span>{auction.suppliers.length}&nbsp;
            //     <span className="icon has-text-warning has-margin-right-xs"><i className="fas fa-adjust"></i></span>0&nbsp;
            //     <span className="icon has-text-danger has-margin-right-xs"><i className="fas fa-times-circle"></i></span>0&nbsp;
            //     <span className="icon has-text-dark has-margin-right-xs"><i className="fas fa-question-circle"></i></span>0&nbsp;
            //   </div>
            // </div>
            <div className="is-none"></div>
            :
            <div className="is-none"></div>
          }
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
