import _ from 'lodash';
import React from 'react';
import { formatUTCDateTime } from '../../../../utilities';

const ClaimsDisplay = ({auctionPayload, isSupplier}) => {
  const auction = _.get(auctionPayload, 'auction');
  let claims = _.get(auctionPayload, 'claims');
  const closedClaims = _.filter(claims, (claim) => claim.closed)
  const openClaims = _.filter(claims, (claim) => !claim.closed)
  claims = isSupplier ? openClaims : claims;

  const handleDisabledClick = (e) => {
    e.preventDefault();
  }

  return(
    <div className="fulfillment-options__history">
      <table className="table is-striped">
        <thead>
          <tr><th colSpan="3">Activity Log</th></tr>
        </thead>
        <tbody>
            { !_.isEmpty(openClaims) && _.map(claims, (claim) => {
                const isClosed = _.get(claim, 'closed', false);
                const timeSubmitted = formatUTCDateTime(_.get(claim, 'inserted_at'));
                const timeClosed = _.get(claim, 'updated_at');
                const claimType = _.get(claim, 'type');
                const vessel = _.get(claim, 'receiving_vessel.name');
                const fuel = _.get(claim, 'delivered_fuel.name');

                return(
                  <tr key={claim.id}>
                    <td>{`${_.capitalize(claimType)} Claim Placed: ${fuel} for ${vessel}`}</td>
                    <td>{timeSubmitted}</td>
                    <td>
                      { !isSupplier ?
                        <a className={`button qa-auction-claims-update_claim-${claim.id}`}
                          {...{href: isClosed ? "" : `/auctions/${auction.id}/claims/${claim.id}/edit`,
                               disabled: isClosed,
                               onClick: isClosed ? handleDisabledClick : undefined}}>Update Claim</a>
                      :
                          <a className={`button qa-auction-claims-view_claim-${claim.id}`}
                             href={`/auctions/${auction.id}/claims/${claim.id}`}>View Claim</a>
                      }
                    </td>
                  </tr>
                );
              })
            }
            { !_.isEmpty(closedClaims) && _.map(closedClaims, (claim) => {
                const timeClosed = formatUTCDateTime(_.get(claim, 'updated_at'));
                const claimType = _.get(claim, 'type');
                const vessel = _.get(claim, 'receiving_vessel.name');
                const fuel = _.get(claim, 'delivered_fuel.name');

                return(
                  <tr key={claim.id}>
                    <td>{`${_.capitalize(claimType)} Claim Resolved: ${fuel} for ${vessel}`}</td>
                    <td>{timeClosed}</td>
                    <td>
                      <a className={`button qa-auction-claims-view_claim-${claim.id}`} href={`/auctions/${auction.id}/claims/${claim.id}`}>View Claim</a>
                    </td>
                  </tr>
                );
              })
            }
          { _.isEmpty(claims) &&
            <tr className="fulfillment-options__history__empty-table"><td colSpan="3"><i>No activities have been logged for this auction.</i></td></tr>
          }
        </tbody>
      </table>
    </div>
  );
};

export default ClaimsDisplay;
