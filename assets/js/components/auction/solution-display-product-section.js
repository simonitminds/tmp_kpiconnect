import React from 'react';
import _ from 'lodash';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';

import { formatTime, formatPrice } from '../../utilities';

const SolutionDisplayProductSection = ({bids, fuel, vesselFuels, supplierId, revokable, revokeBid, auctionPayload}) => {
  const sortedBids = _.sortBy(bids, [
      ({vessel_fuel_id}) => _.find(vesselFuels, (vf) => vf.id == vessel_fuel_id).vessel_id
    ]);
  const supplierName = (bid, selfText) => {
    const supplierText = selfText || "Your Bid";

    if(supplierId) {
      return bid.supplier_id == supplierId ? supplierText : "";
    } else {
      return bid.supplier;
    }
  }


  const isTradedBid = (bid) => {
    return(
      <span>
        { bid.is_traded_bid
          ? <span className="auction__traded-bid-tag">
              <i action-label="Traded Bid" className="fas fa-exchange-alt auction__traded-bid-marker"></i>
              <span className="has-padding-left-sm">Traded Bid</span>
            </span>
          : ""
        }
      </span>
    );
  }

  const isNonsplittableBid = (bid) => {
    return(
      <span>
        { bid.allow_split == false
          ? <span className="auction__nonsplittable-bid-tag">
              <i action-label="Can't Be Split" className="fas fa-ban auction__nonsplittable-bid-marker"></i>
              <span className="has-padding-left-sm">Unsplittable</span>
            </span>
          : ""
        }
      </span>
    );
  }

  const confirmBidRevoke = (ev) => {
    ev.preventDefault();
    const productId = ev.currentTarget.dataset.productId;
    const auctionId = auctionPayload.auction.id;
    const vesselFuel = _.find(vesselFuels, ({id}) => `${id}` == productId);

    return confirm(`Are you sure you want to cancel your bid for ${vesselFuel.fuel.name} to ${vesselFuel.vessel.name}?`) ? revokeBid(auctionId, productId) : false;
  };


  return (
    <table className="auction-solution__product-table table is-striped">
      <thead>
        <tr>
          <th colSpan="4">{fuel.name}</th>
        </tr>
      </thead>
      <tbody>
        { sortedBids.length > 0
          ? _.map(sortedBids, (bid) => {
              const vesselFuel = _.find(vesselFuels, ({id}) => `${id}` == bid.vessel_fuel_id);
              const vessel = vesselFuel.vessel;

              return (
                <tr key={bid.id} className={`qa-auction-bid-${bid.id}`}>
                  <td className="auction-solution__product-table__vessel">{vessel.name} <span className="has-text-gray-3 has-margin-left-xs">({vessel.imo})</span>
                  { revokable &&
                      <span className={`tag auction-solution__product-table__revoke revoke-bid__button has-margin-left-auto qa-auction-product-${vesselFuel.id}-revoke`} onClick={confirmBidRevoke} data-product-id={vesselFuel.id}>
                        <i className="fas fa-times"></i>
                      </span>
                  }
                  </td>
                  <td className="auction-solution__product-table__bid">
                    { bid
                      ? <span>
                          <span className="auction__bid-amount qa-auction-bid-amount">${formatPrice(bid.amount)}<span className="has-text-gray-3">/unit</span> &times; {vesselFuel.quantity} MT </span>
                          <span className="auction__traded-bid-tag__container qa-auction-bid-is_traded_bid">{isTradedBid(bid)}</span>
                          <span className="auction__nonsplittable-bid-tag__container qa-auction-bid-is_nonsplittable_bid">{isNonsplittableBid(bid)}</span>
                        </span>
                      : <i>No bid</i>
                    }
                  </td>
                  <td className="auction-solution__product-table__supplier"><span className="qa-auction-bid-supplier">
                    { supplierName(bid) == "Your Bid" ?
                      <span className="tag auction-solution__your-bid-tag">
                        { supplierName(bid) }
                      </span>:
                      supplierName(bid)
                    }
                    </span></td>
                  <td className="auction-solution__product-table__bid-time"><span className="qa-auction-bid-time_entered">({ formatTime(bid.time_entered) })</span></td>
                  { revokable &&
                    <td className="auction-solution__product-table__revoke">
                      <span className={`tag revoke-bid__button qa-auction-product-${vesselFuel.id}-revoke`} onClick={confirmBidRevoke} data-product-id={vesselFuel.id}>
                        <i className="fas fa-times"></i>
                      </span>
                    </td>
                  }
                </tr>
              );
            })
          : <tr>
              <td colSpan="3">
                <i>No bids have been placed for this product</i>
              </td>
              <td></td>
            </tr>
        }
      </tbody>
    </table>

  );
};


export default SolutionDisplayProductSection;
