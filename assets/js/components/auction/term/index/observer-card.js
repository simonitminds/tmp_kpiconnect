import _ from 'lodash';
import React from 'react';
import moment from 'moment';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { cardDateFormat, etaAndEtdForAuction, formatPrice, formatMonthYear } from '../../../../utilities';
import SupplierBidStatus from '../show/supplier-bid-status';
import AuctionTimeRemaining from '../../common/auction-time-remaining';
import AuctionTitle from '../../common/auction-title';
import LowestBidMessage from '../../common/index/lowest-bid-message';
import SuppliersParticipating from '../../common/index/suppliers-participating';
import FuelPriceDisplay from '../../common/index/fuel-price-display';

const ObserverCard = ({auctionPayload, timeRemaining}) => {
  const auction = _.get(auctionPayload, 'auction');
  const auctionType = _.get(auction, 'type');
  const vessels = _.get(auction, 'vessels');
  const startDate = _.get(auction, 'start_date');
  const endDate = _.get(auction, 'end_date');
  const fuel = _.get(auction, 'fuel');
  const fuelIndex = _.get(auction, 'fuel_index');
  const fuelQuantity = _.get(auction, 'fuel_quantity');
  const auctionStatus = _.get(auctionPayload, 'status');
  const bestSolution = _.get(auctionPayload, 'solutions.best_overall');
  const winningSolution = _.get(auctionPayload, 'solutions.winning_solution');

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

  const vesselNameDisplay = _.chain(vessels).map('name').join(", ").value();

  const solution = auctionStatus == 'closed' ? winningSolution : bestSolution;
  const productBid = _.chain(solution)
    .get('bids', [])
    .nth(0)
    .value() || '';
  const products = [{fuel: fuel, quantity: fuelQuantity, bid: productBid}];
  const preAuctionStatus = auctionStatus == "pending" || auctionStatus == "draft";
  const productLabel = () => { if(auctionStatus == 'closed'){ return 'Winning Prices'} else { return 'Leading Offer Prices'} };

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
            <div className="auction-card__buttons">
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
          <p className="has-family-header"><span className="has-text-weight-bold">{vesselNameDisplay}</span> ({formatMonthYear(startDate)}<span className="is-hidden-mobile"> &ndash; {formatMonthYear(endDate)}</span>)</p>
          {auctionType == "formula_related" ?
            <p className="has-family-header"><span className="has-text-weight-bold">Index</span> <span className="is-hidden-mobile">{fuelIndex ? fuelIndex.name : "—"}</span></p> :
            ""
          }
        </div>
        <div className="card-content__products">
          <span className="card-content__product-header">{preAuctionStatus ? 'Products' : productLabel() } <span className={`qa-auction-${auctionType}`}>({_.startCase(auctionType)})</span></span>
          <FuelPriceDisplay products={products} auctionType={auctionType} auctionStatus={auctionStatus} />
        </div>
        { auctionStatus == 'pending' && window.isAdmin &&
          <div className="card-content__products">
            <a href={`/auctions/${auction.id}/start`} className="card__start-auction button is-link is-small has-margin-left-sm qa-auction-start">
              <span className="icon"><FontAwesomeIcon icon="play" /></span> Start Auction
            </a>
          </div>
        }

        { auctionStatus == 'pending' || auctionStatus == 'open'
            ? <div className="card-content__auction-status">
              <SuppliersParticipating auctionPayload={auctionPayload} />
            </div>
          : ""
        }
        { bidStatusDisplay() }
      </div>
    </div>
  );
};

export default ObserverCard;
