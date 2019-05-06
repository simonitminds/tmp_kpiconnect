import _ from 'lodash';
import React from 'react';
import FixtureDisplay from './fixture-display';

const FullfillmentOptions = ({auctionPayload}) => {
  const auctionID = _.get(auctionPayload, 'auction.id')

  return(
    <div class="box fulfillment-options">
      <h2>Order Status: </h2>
      <div class="fulfillment-options__actions">
        <h3 class="has-margin-right-md is-inline-block">Options</h3>
        <a href={`/auctions/${auctionId}/claims/new`} class="button is-primary">Place Claim</a>
      </div>
      <FixtureDisplay auctionPayload={auctionPayload} />
      <div class="fulfillment-options__history">
        <table class="table is-striped">
          <thead>
            <tr><th>Activity Log</th></tr>
          </thead>
          <tbody>
            <tr>
              <td>
                Pre-Delivery Fixture Change
              </td>
              <td>
                14/12/2018 20:51
              </td>
              <td></td>
            </tr>
            <tr>
              <td>
                Quantity Claim Placed: MGO (DMA) for Al Jasra
              </td>
              <td>
                15/12/2018 16:20
              </td>
              <td><button class="button" disabled>Update Claim</button></td>
            </tr>
            <tr>
              <td>
                Quality Claim Placed: MGO (DMA) for Al Jasra
              </td>
              <td>
                15/12/2018 16:25
              </td>
              <td><button class="button">Update Claim</button></td>
            </tr>
            <tr>
              <td>
                Quantity Claim Resolved: MGO (DMA) for Al Jasra
              </td>
              <td>
                15/12/2018 16:20
              </td>
              <td><button class="button">View Claim</button></td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default FullfillmentOptions;
