import _ from 'lodash';
import React from 'react';
import moment from 'moment';
import { formatPrice } from '../../utilities';
import SupplierBidStatus from './supplier-bid-status'
import AuctionTimeRemaining from './auction-time-remaining';

const SupplierAuctionCard = ({auctionPayload, timeRemaining, connection, currentUserCompanyId}) => {
  const auction = _.get(auctionPayload, 'auction');
  const auctionStatus = _.get(auctionPayload, 'status');
  const cardDateFormat = (time) => { return moment(time).format("DD MMM YYYY, k:mm"); };
  const vessels = _.get(auction, 'vessels');
  const fuels = _.get(auction, 'fuels');
  const vesselFuels = _.get(auction, 'auction_vessel_fuels');
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

    const solutionBidsByFuel = _.chain(solution)
      .get('bids', [])
      .reduce((acc, bid) => {
        acc[bid.fuel_id] = bid;
        return acc;
      }, {})
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
              <a href={`/auctions/${auction.id}`} action-label="Go To Auction" className="auction-card__link-to-auction"><span className="icon is-medium has-text-right"><i className="fas fa-2x fa-angle-right"></i></span></a>
            {/* End Link to Auction */}
          </div>
        </div>
        <div className="card-title">
          <h3 className="title is-size-4 has-text-weight-bold is-marginless">
          <span className="has-text-gray-3 is-inline-block has-padding-right-sm">{auction.id}</span>
            {vesselNameDisplay(vesselFuels)}
            {auction.is_traded_bid_allowed && <span> <i action-label="Traded Bids Accepted" className="fas fa-exchange-alt has-text-gray-3 card__traded-bid-marker"></i> </span>}
          </h3>
          <p className="has-family-header has-margin-bottom-xs">{auction.buyer.name}</p>
          <p className="has-family-header"><span className="has-text-weight-bold">{auction.port.name}</span> (<strong>ETA</strong> {cardDateFormat(auction.eta)}<span className="is-hidden-mobile"> &ndash; <strong>ETD</strong> {cardDateFormat(auction.etd)}</span>)</p>
        </div>
        <div className="card-content__products">
          { auctionStatus != 'pending' &&
            <span className="card-content__product-header">{auctionStatus == 'closed' ? 'Winning' : 'Leading Offer'} Prices</span>
          }
          { fuelPriceDisplay(vesselFuels, ((auctionStatus == closed) ? winningSolution : bestSolution)) }
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
