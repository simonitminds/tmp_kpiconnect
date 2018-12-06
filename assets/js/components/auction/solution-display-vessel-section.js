import React from 'react';
import _ from 'lodash';
import { formatTime, formatPrice } from '../../utilities';

const SolutionDisplayVesselSection = ({bids, vessel, supplierId, auctionPayload}) => {
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


  return (
    <table className="auction-solution__product-table table is-striped">
      <thead>
        <tr>
          <th colSpan="3">{vessel.name} <span className="has-text-gray-3">({vessel.imo})</span></th>
        </tr>
      </thead>
      <tbody>
        { bids.length > 0
          ? _.map(bids, (bid) => {
              return (
                <tr key={bid.id} className={`qa-auction-bid-${bid.id}`}>
                  <td>{vessel.name}</td>

                  <td>
                    { bid
                      ? <span>
                          <span className="auction__bid-amount qa-auction-bid-amount">${formatPrice(bid.amount)}<span className="has-text-gray-3">/unit</span> &times; 1000 MT </span>
                          <span className="auction__traded-bid-tag__container qa-auction-bid-is_traded_bid">{isTradedBid(bid)}</span>
                          <span className="auction__nonsplittable-bid-tag__container qa-auction-bid-is_nonsplittable_bid">{isNonsplittableBid(bid)}</span>
                        </span>
                      : <i>No bid</i>
                    }
                  </td>
                  <td><span className="qa-auction-bid-supplier">{ supplierName(bid) }</span></td>
                  <td><span className="qa-auction-bid-supplier">({ formatTime(bid.time_entered) })</span></td>
                </tr>
              );
            })
          : <tr>
              <td>
                <i>No bids have been placed on this auction</i>
              </td>
            </tr>
        }
      </tbody>
    </table>

  );
};


export default SolutionDisplayVesselSection;
