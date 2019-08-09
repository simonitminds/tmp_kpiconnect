import _ from 'lodash';
import React from 'react';
import moment from 'moment';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { cardDateFormat, etaAndEtdForAuction, formatPrice } from '../../../../utilities';
import SupplierBidStatus from '../show/supplier-bid-status';
import AuctionTimeRemaining from '../../common/auction-time-remaining';
import AuctionTitle from '../../common/auction-title';
import LowestBidMessage from '../../common/index/lowest-bid-message';
import SuppliersParticipating from '../../common/index/suppliers-participating';
import FuelPriceDisplay from '../../common/index/fuel-price-display';

const BuyerCard = ({auctionPayload, timeRemaining}) => {
  const auction = _.get(auctionPayload, 'auction');
  const claims = _.get(auctionPayload, 'claims');
  const auctionType = _.get(auction, 'type');
  const vessels = _.get(auction, 'vessels');
  const { eta, etd } = etaAndEtdForAuction(auction);
  const fuels = _.get(auction, 'fuels');
  const vesselFuels = _.get(auction, 'auction_vessel_fuels');
  const auctionStatus = _.get(auctionPayload, 'status');
  const bestSolution = _.get(auctionPayload, 'solutions.best_overall');
  const winningSolution = _.get(auctionPayload, 'solutions.winning_solution');
  const otherSolutions = _.get(auctionPayload, 'solutions.other_solutions');

  const confirmCancellation = (e) => {
    e.preventDefault();
    return confirm('Are you sure you want to cancel this auction?') ? window.location = `/auctions/${auction.id}/cancel` : false;
  };

  const confirmClone = (e) => {
    e.preventDefault();
    return confirm('Are you sure you want to clone this auction?') ? window.location = `/auctions/${auction.id}/clone` : false;
  };

  const claimStatusDisplay = () => {
    let openClaims = _
      .chain(claims)
      .filter((claim) => !claim.closed)
      .value();
    openClaims = openClaims.length

    if (auctionStatus == 'closed' && !isObserver) {
      if (!_.isEmpty(claims)) {
        return (
          <span className="tag is-yellow is-flex has-text-centered has-text-weight-bold"><span className="qa-open-claims has-margin-right-xs">{openClaims}</span> {`Open Claim${openClaims != 1 ? "s" : ""}`}</span>
        );
      } else {
        return <i>No activities have been logged for this auction.</i>;
      }
    } else {
      return "";
    }
  }

  const bidStatusDisplay = () => {
    if (auctionStatus != 'pending' && bestSolution) {
      return (
        <div className="card-content__bid-status">
          <LowestBidMessage auctionPayload={auctionPayload} />
        </div>
      );
    } else {
      return "";
    }
  }

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

  // const solution = auctionStatus == 'closed' ? winningSolution : bestSolution;
  const solution = () => {
    if (auctionStatus === 'closed') {
      return winningSolution;
    } else if (!!bestSolution) {
      return bestSolution;
    } else {
      return otherSolutions[0];
    }
  }

  const solutionBidsByFuel =  _.chain(solution())
    .get('bids', [])
    .groupBy((bid) => fuelForVesselFuels[bid.vessel_fuel_id])
    .mapValues((bids) => _.chain(bids).filter().minBy('amount').value())
    .value();

  const products = _.map(uniqueFuels, (fuel) => {
    return {fuel: fuel, quantity: fuelQuantities[fuel.id], bid: solutionBidsByFuel[fuel.id]};
  });

  const preAuctionStatus = auctionStatus == "pending";
  const productLabel = () => { if(auctionStatus == 'closed'){ return 'Winning Prices'} else { return 'Leading Offer Prices'} };

  return (
    <div className="column is-one-third-desktop is-half-tablet">
      <div className={`card card--auction qa-auction-${auction.id}`}>
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
              { (auctionStatus == 'pending') &&
                <a href={`/auctions/${auction.id}/edit`} action-label="Edit Auction" className="auction-card__link-to-auction-edit is-hidden-420">
                  <span className="icon is-medium has-text-right">
                    <FontAwesomeIcon icon="edit" size="lg" />
                  </span>
                </a>
              }
              { !(auctionStatus == 'canceled' || auctionStatus == 'closed' || auctionStatus == 'expired')
                ? <a id="cancel-auction" href={`/auctions/${auction.id}/cancel`} onClick={() => confirmCancellation()} action-label="Cancel Auction" className="auction-card__link-to-auction-cancel is-hidden-420 qa-auction-cancel">
                    <span className="icon is-medium has-text-right">
                      <FontAwesomeIcon icon="times" size="lg" />
                    </span>
                  </a>
                : <span></span>
              }
              <a id="clone-auction" href={`/auctions/${auction.id}/clone`} onClick={(e) => confirmClone(e)} action-label="Clone Auction" className="auction-card__link-to-auction-cancel is-hidden-420 qa-auction-clone">
                <span className="icon is-medium has-text-right">
                  <FontAwesomeIcon icon="copy" size="lg" />
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
          <p className="has-family-header has-margin-bottom-xs">{auction.buyer ? auction.buyer.name : 'Buyer Company Name'}</p>
          <p className="has-family-header"><span className="has-text-weight-bold">{auction.port.name}</span> (<strong>ETA</strong> {cardDateFormat(eta)}<span className="is-hidden-mobile"> &ndash; <strong>ETD</strong> {cardDateFormat(etd)}</span>)</p>
          { claimStatusDisplay() }
        </div>
        <div className="card-content__products">
          <span className="card-content__product-header">{preAuctionStatus ? 'Products' : productLabel() }</span>
          <FuelPriceDisplay products={products} auctionType={auctionType} auctionStatus={auctionStatus} />
        </div>
        { auctionStatus == 'pending'
          ? <div className="card-content__products">
              { window.isAdmin &&
                <a href={`/auctions/${auction.id}/start`} className="card__start-auction button is-link is-small has-margin-left-sm qa-auction-start">
                  <span className="icon"><FontAwesomeIcon icon="play" /></span> Start Auction
                </a>
              }
            </div>
          : ""
        }
        { auctionStatus == 'pending' || auctionStatus == 'open'
            ? <div className="card-content__auction-status">
              <SuppliersParticipating auctionPayload={auctionPayload} />
            </div>
          : ""
        }
        { bidStatusDisplay() }
    {/* ADMIN ONLY */}
        {/* <div className="card-content__bid-status">
          <div className="card-content__best-bidder">Lowest Bidder [Supplier(s)]</div>
          <div className="card-content__best-price"><strong>Their Offer: </strong>PRICE</div>
        </div>
        <div className="card-content__bid">
          <div className="card-content__bid__title has-padding-right-xs">
            <div>Place Bid</div>
            <span className="icon is-inline-block has-text-dark has-margin-left-md"><FontAwesomeIcon icon="plus" /></span>
          </div>
        </div>
        <div className="card-content__bid">
          <div className="card-content__bid__title">
            <div>Change RSVP</div>
            <div className="card-content__change-rsvp">
              <div className="card-content__rsvp">
                <span className="icon has-text-success has-margin-right-xs"><FontAwesomeIcon icon="check-circle" /></span>0&nbsp;
                <span className="icon has-text-warning has-margin-right-xs"><FontAwesomeIcon icon="adjust" /></span>0&nbsp;
                <span className="icon has-text-danger has-margin-right-xs"><FontAwesomeIcon icon="times-circle" /></span>0&nbsp;
                <span className="icon has-text-dark has-margin-right-xs"><FontAwesomeIcon icon="question-circle" /></span>0&nbsp;
              </div>
              <span className="icon is-inline-block has-text-dark has-margin-left-md"><FontAwesomeIcon icon="plus" /></span>
            </div>
          </div>
        </div> */}
    {/* / ADMIN ONLY */}
      </div>
    </div>
  );
}

export default BuyerCard;
