import _ from 'lodash';
import React from 'react';
import FixturesDisplay from './fixtures-display';
import ClaimsDisplay from './claims-display';

const FullfillmentOptions = ({auctionPayload}) => {
  const auctionID = _.get(auctionPayload, 'auction.id')

  return(
    <div class="box fulfillment-options">
      <h2>Order Status: </h2>
      <div class="fulfillment-options__actions">
        <h3 class="has-margin-right-md is-inline-block">Options</h3>
        <a href={`/auctions/${auctionId}/claims/new`} class="button is-primary">Place Claim</a>
      </div>
      <FixturesDisplay auctionPayload={auctionPayload} />
      <ClaimsDisplay auctionPayload={auctionPayload} />
    </div>
  );
};

export default FullfillmentOptions;
