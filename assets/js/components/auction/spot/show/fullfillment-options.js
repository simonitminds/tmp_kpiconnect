import _ from 'lodash';
import React from 'react';
import FixturesDisplay from './fixtures-display';
import ClaimsDisplay from './claims-display';

const FullfillmentOptions = ({auctionPayload, isSupplier}) => {
  const auctionID = _.get(auctionPayload, 'auction.id')
  const fixtures = _.get(auctionPayload, 'fixtures');
  return(
    <div className="box fulfillment-options">
        <h2>Fullfillment Options</h2>
        { !isSupplier &&
          <div className="fulfillment-options__actions">
            <h3 className="has-margin-right-md is-inline-block">Options</h3>
            <a href={`/auctions/${auctionId}/claims/new`} className="button is-primary qa-auction-claims-place_claim">Place Claim</a>
          </div>
        }
      <FixturesDisplay auctionPayload={auctionPayload} />
      <ClaimsDisplay auctionPayload={auctionPayload} isSupplier={isSupplier} />
    </div>
  );
};

export default FullfillmentOptions;
