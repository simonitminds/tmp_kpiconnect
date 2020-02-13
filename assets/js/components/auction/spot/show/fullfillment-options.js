import _ from 'lodash';
import React from 'react';
import FixturesDisplay from './fixtures-display';
import ClaimsDisplay from './claims-display';

const FullfillmentOptions = ({ addCOQ, deleteCOQ, auctionPayload, isSupplier }) => {
  const fixtures = _.get(auctionPayload, 'fixtures');
  const displayOrderStatus = () => {
    if (_.every(fixtures, { delivered: false })) {
      return 'Pre-Delivery';
    } else if (_.every(fixtures, { delivered: true })) {
      return 'Post-Delivery';
    } else {
      return 'Partial-Delivery';
    }
  }


  return (
    <div className="box fulfillment-options">
      <h2>Order Status: {displayOrderStatus()}</h2>
      {!isSupplier &&
        <div className="fulfillment-options__actions">
          <h3 className="has-margin-right-md is-inline-block">Options</h3>
          <a href={`/auctions/${auctionId}/claims/new`} className="button is-primary qa-auction-claims-place_claim">Place Claim</a>
        </div>
      }
      <FixturesDisplay addCOQ={addCOQ} deleteCOQ={deleteCOQ} auctionPayload={auctionPayload} isSupplier={isSupplier} />
      <ClaimsDisplay auctionPayload={auctionPayload} isSupplier={isSupplier} />
    </div>
  );
};

export default FullfillmentOptions;
