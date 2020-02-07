import React from 'react';
import _ from 'lodash';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { formatTime, formatPrice } from '../../../../../utilities';
import TradedBidTag from '../../../common/show/traded-bid-tag';
import NonSplittableBidTag from '../../../common/show/non-splittable-bid-tag';

const SolutionDisplayProductSection = ({ bids, fuel, vesselFuels, supplierId, highlightOwn, revokable, revokeBid, auctionPayload }) => {
  const isAdmin = window.isAdmin && !window.isImpersonating;
  const isObserver = window.isObserver;
  const sortedBids = _.sortBy(bids, [
    ({ vessel_fuel_id }) => _.find(vesselFuels, (vf) => vf.id == vessel_fuel_id).vessel_id
  ]);
  const supplierName = (bid, selfText) => {
    const supplierText = selfText || "Your Bid";

    if (supplierId) {
      return bid.supplier_id == supplierId ? supplierText : "";
    } else {
      return bid.supplier;
    }
  }


  const isTradedBid = (bid) => {
    return (
      <span>
        {bid.is_traded_bid
          ? <TradedBidTag />
          : ""
        }
      </span>
    );
  }

  const isNonsplittableBid = (bid) => {
    return (
      <span>
        {bid.allow_split == false
          ? <NonSplittableBidTag />
          : ""
        }
      </span>
    );
  }

  const confirmBidRevoke = (ev) => {
    ev.preventDefault();
    const productId = ev.currentTarget.dataset.productId;
    const auctionId = auctionPayload.auction.id;
    const vesselFuel = _.find(vesselFuels, ({ id }) => `${id}` == productId);

    return confirm(`Are you sure you want to cancel your bid for ${vesselFuel.fuel.name} to ${vesselFuel.vessel.name}?`) ? revokeBid(auctionId, productId) : false;
  };

  return (
    <table className="auction-solution__product-table table is-gray-1">
      <thead>
        <tr className="is-white">
          <th colSpan="4">{fuel.name}</th>
        </tr>
      </thead>
      <tbody>
        {sortedBids.length > 0
          ? _.map(sortedBids, (bid) => {
            const vesselFuel = _.find(vesselFuels, ({ id }) => `${id}` == bid.vessel_fuel_id);
            const vessel = vesselFuel.vessel;

            return (
              <React.Fragment key={bid.id}>
                <tr className={`qa-auction-bid-${bid.id}`}>
                  <td className="auction-solution__product-table__vessel">
                    {vessel.name} <span className="has-text-gray-3 has-margin-left-xs">({vessel.imo})</span>
                  </td>
                  <td className="auction-solution__product-table__bid">
                    {bid
                      ? <span>
                          <span className="auction__bid-amount qa-auction-bid-amount">${formatPrice(bid.amount)}<span className="has-text-gray-3">/unit</span> &times; {vesselFuel.quantity} MT </span>
                          <span className="auction__traded-bid-tag__container qa-auction-bid-is_traded_bid">{isTradedBid(bid)}</span>
                          <span className="auction__nonsplittable-bid-tag__container qa-auction-bid-is_nonsplittable_bid">{isNonsplittableBid(bid)}</span>
                        </span>
                      : <i>No bid</i>
                    }
                  </td>
                  <td className="auction-solution__product-table__supplier">
                    <span className="qa-auction-bid-supplier">
                      {supplierName(bid) == "Your Bid" && highlightOwn
                        ? <span className="tag auction-solution__your-bid-tag">
                            {supplierName(bid)}
                          </span>
                        : supplierName(bid)
                      }
                    </span>
                  </td>
                  <td className="auction-solution__product-table__bid-time"><span className="qa-auction-bid-time_entered">({formatTime(bid.time_entered)})</span></td>
                  {bid.supplier_id == supplierId && !isAdmin && !isObserver && revokable &&
                    <td className="auction-solution__product-table__revoke">
                      <span className={`tag revoke-bid__button qa-auction-product-${vesselFuel.id}-revoke`} onClick={confirmBidRevoke} data-product-id={vesselFuel.id}>
                        <FontAwesomeIcon icon="times" />
                      </span>
                    </td>
                  }
                </tr>
                {bid.comment && <tr><td className="auction-solution__product-table__bid-comment"><b>Comment: </b><span className={`qa-auction-bid-comment-${bid.id}`}>{bid.comment}</span></td></tr>}
              </React.Fragment>
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
