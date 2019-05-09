import _ from 'lodash';
import React from 'react';
import { formatUTCDateTime } from '../../../../utilities';

const ClaimsDisplay = ({auctionPayload}) => {
  const auction = _.get(auctionPayload, 'auction');
  const claims = _.get(auctionPayload, 'claims');
  const closedClaims = _.filter(claims, (claim) => claim.closed)

  return(
    <div class="fulfillment-options__history">
      <table class="table is-striped">
        <thead>
          <tr><th colspan="3">Activity Log</th></tr>
        </thead>
        <tbody>
          { _.map(claims, (claim) => {
              const isClosed = _.get(claim, 'closed', false);
              const timeSubmitted = formatUTCDateTime(_.get(claim, 'inserted_at'));
              const timeClosed = _.get(claim, 'updated_at');
              const claimType = _.get(claim, 'type');
              const vessel = _.get(claim, 'receiving_vessel.name');
              const fuel = _.get(claim, 'delivered_fuel.name');

              return(
                <tr>
                  <td>{`${_.capitalize(claimType)} Claim Placed: ${fuel} for ${vessel}`}</td>
                  <td>{timeSubmitted}</td>
                  <td>
                    <a className="button" {...{href: isClosed ? "" : `/auctions/${auction.id}/claims/${claim.id}/edit`, disabled: isClosed}}>Update Claim</a>
                  </td>
                </tr>
              );
            })
          }
          { _.map(closedClaims, (claim) => {
              const timeClosed = formatUTCDateTime(_.get(claim, 'updated_at'));
              const claimType = _.get(claim, 'type');
              const vessel = _.get(claim, 'receiving_vessel.name');
              const fuel = _.get(claim, 'delivered_fuel.name');

              return(
                <tr>
                  <td>{`${_.capitalize(claimType)} Claim Resolved: ${fuel} for ${vessel}`}</td>
                  <td>{timeClosed}</td>
                  <td>
                    <a className="button" href={`/auctions/${auction.id}/claims/${claim.id}`}>View Claim</a>
                  </td>
                </tr>
              );
            })
          }
          <tr class="fulfillment-options__history__empty-table"><td colspan="3"><i>No activities have been logged for this auction.</i></td></tr>
        </tbody>
      </table>
    </div>
  );
};

export default ClaimsDisplay;
