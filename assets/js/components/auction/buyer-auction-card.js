import _ from 'lodash';
import React from 'react';
import moment from 'moment';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { cardDateFormat, etaAndEtdForAuction, formatPrice } from '../../utilities';
import SupplierBidStatus from './supplier-bid-status';
import AuctionTimeRemaining from './auction-time-remaining';

const BuyerAuctionCard = ({auctionPayload, timeRemaining}) => {
  const auction = _.get(auctionPayload, 'auction');
  const vessels = _.get(auction, 'vessels');
  const { eta, etd } = etaAndEtdForAuction(auction);
  const fuels = _.get(auction, 'fuels');
  const vesselFuels = _.get(auction, 'auction_vessel_fuels');
  const auctionStatus = _.get(auctionPayload, 'status');
  const bestSolution = _.get(auctionPayload, 'solutions.best_overall');
  const winningSolution = _.get(auctionPayload, 'solutions.winning_solution');
  const participations = _.get(auctionPayload, 'participations');
  const participationCounts = _.countBy(participations, _.identity);
  const {"yes": rsvpYesCount, "no": rsvpNoCount, "maybe": rsvpMaybeCount, null: rsvpNoResponseCount} = participationCounts;

  const confirmCancellation = () => { return confirm('Are you sure you want to cancel this auction?') ? window.open(`/auctions/${auction.id}/cancel`) : false; };

  const lowestBidMessage = () => {
    if (winningSolution) {
      const suppliers = _.chain(winningSolution.bids).map("supplier").uniq().value();
      if(suppliers.length == 1) {
        return (
          <div className="card-content__best-bidder card-content__best-bidder--winner">
            <div className="card-content__best-bidder__name">Winner: {suppliers[0]}</div>
          </div>
        )
      } else {
        return (
          <div className="card-content__best-bidder card-content__best-bidder--winner">
            <div className="card-content__best-bidder__name">Winner: {suppliers[0]}</div><div className="card-content__best-bidder__count">(+{suppliers.length - 1})</div>
          </div>
        )
      }
    } else if (auctionStatus == 'expired') {
      return (
        <div className="card-content__best-bidder">
          <div className="card-content__best-bidder__name">No offer was selected</div>
        </div>
      )
    } else if (bestSolution) {
      const suppliers = _.chain(bestSolution.bids).map("supplier").uniq().value();
      return (
        <div className="card-content__best-bidder">
          <div className="card-content__best-bidder__name">Best Solution: {suppliers[0]}</div>{suppliers.length > 1 && <div className="card-content__best-bidder__count">(+{suppliers.length - 1})</div>}
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

  const fuelPriceDisplay = (vesselFuels, solution) => {
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

    const solutionBidsByFuel =  _.chain(solution)
      .get('bids', [])
      .groupBy((bid) => fuelForVesselFuels[bid.vessel_fuel_id])
      .mapValues((bids) => _.chain(bids).filter().minBy('amount').value())
      .value();

    return _.map(uniqueFuels, (fuel) => {
      const fuelBid = solutionBidsByFuel[fuel.id];

      return(
        <div className="card-content__product" key={fuel.id}>
          <span className="fuel-name">{fuel.name}</span>
          { fuelQuantities[fuel.id]
            ? <span className="fuel-amount has-text-gray-3">({fuelQuantities[fuel.id]}&nbsp;MT)</span>
            : <span className="no-amount has-text-gray-3">(no quantity given)</span>
          }
          <span className="card-content__best-price">
            { fuelBid
              ? `$${formatPrice(fuelBid.amount)}`
              : "No bid"
            }
          </span>
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
            <div className={`auction-status auction-status--${auctionStatus}`}>
              <span className="qa-auction-status">{auctionStatus}</span>
              <AuctionTimeRemaining auctionPayload={auctionPayload} auctionTimer={timeRemaining} />
            </div>
            {/* End Status/Time Bubble */}
            {/* Start Link to Auction Edit/Delete */}
            <div className="auction-card__buttons">
              { (auctionStatus == 'draft' || auctionStatus == 'pending') &&
                <a href={`/auctions/${auction.id}/edit`} action-label="Edit Auction" className="auction-card__link-to-auction-edit is-hidden-420">
                  <span className="icon is-medium has-text-right">
                    <FontAwesomeIcon icon="edit" size="lg" />
                  </span>
                </a>
              }
              { !(auctionStatus == 'canceled' || auctionStatus == 'closed' || auctionStatus == 'expired')
                ? <a id="cancel-auction" href="" onClick={() => confirmCancellation()} action-label="Cancel Auction" className="auction-card__link-to-auction-cancel is-hidden-420 qa-auction-cancel">
                    <span className="icon is-medium has-text-right">
                      <FontAwesomeIcon icon="times" size="lg" />
                    </span>
                  </a>
                : <span></span>
              }
              {/* End Link to Auction Edit/Delete */}
              {/* Start Link to Auction */}
                <a href={`/auctions/${auction.id}`} action-label="Go To Auction" className="auction-card__link-to-auction"><span className="icon is-medium has-text-right"><FontAwesomeIcon icon="angle-right" size="2x" /></span></a>
              {/* End Link to Auction */}
            </div>
          </div>
        </div>
        <div className="card-title">
          <h3 className="title is-size-4 has-text-weight-bold is-marginless">
          <span className="has-text-gray-3 is-inline-block has-padding-right-sm">{auction.id}</span>
            { vesselNameDisplay(vesselFuels) }
            {auction.is_traded_bid_allowed && <span> <FontAwesomeIcon icon="exchange-alt" className="has-text-gray-3 card__traded-bid-marker" action-label="Traded Bids Accepted" /> </span>}
          </h3>
          <p className="has-family-header has-margin-bottom-xs">{auction.buyer.name}</p>
          <p className="has-family-header"><span className="has-text-weight-bold">{auction.port.name}</span> (<strong>ETA</strong> {cardDateFormat(eta)}<span className="is-hidden-mobile"> &ndash; <strong>ETD</strong> {cardDateFormat(etd)}</span>)</p>
        </div>
        <div className="card-content__products">
          { auctionStatus != 'pending' &&
            <span className="card-content__product-header">{auctionStatus == 'closed' ? 'Winning' : 'Leading Offer'} Prices</span>
          }
          { fuelPriceDisplay(vesselFuels, ((auctionStatus == closed) ? winningSolution : bestSolution)) }
        </div>
        { auctionStatus == 'pending'
          ? <div className="card-content__products">
              { window.isAdmin &&
                <a href={`/auctions/${auction.id}/start`} className="card__start-auction button is-link is-small has-margin-left-sm qa-auction-start">
                  <span className="icon"><FontAwesomeIcon icon="play" /></span> Start Auction
                </a>
              }
            </div>
          : <div className="is-none"></div>
        }

        <div>
          { auctionStatus == 'pending' || auctionStatus == 'open'
            ? <div className="card-content__auction-status">
                <div>Suppliers Participating</div>
                <div className="card-content__rsvp qa-auction-suppliers">
                  <span className="icon has-text-success has-margin-right-xs"><FontAwesomeIcon icon="check-circle" /></span>{rsvpYesCount || "0"}&nbsp;
                  <span className="icon has-text-warning has-margin-right-xs"><FontAwesomeIcon icon="adjust" /></span>{rsvpMaybeCount || "0"}&nbsp;
                  <span className="icon has-text-danger has-margin-right-xs"><FontAwesomeIcon icon="times-circle" /></span>{rsvpNoCount || "0"}&nbsp;
                  <span className="icon has-text-dark has-margin-right-xs"><FontAwesomeIcon icon="question-circle" /></span>{rsvpNoResponseCount || "0"}&nbsp;
                </div>
              </div>
            : <div className="is-none"></div>
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

export default BuyerAuctionCard;
