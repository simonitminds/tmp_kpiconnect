import React from 'react';
import _ from 'lodash';
import { formatTime, formatPrice } from '../../utilities';

const SupplierBidList = ({auction, buyer}) => {
  const fuel = _.get(auction, 'fuel.name');
  const bidList = _.get(auction, 'bid_list', []);
  const winningBidIds = _.chain(auction)
    .get('state.winning_bids', [])
    .map('id')
    .value();

    if (bidList.length > 0 ) {
      return(
        <div className="box has-margin-top-lg">
          <h3 className="box__header box__header--bordered">Your Bid History</h3>
          <table className="table is-fullwidth is-striped is-marginless qa-auction-bids">
            <thead>
              <tr>
                <th>{fuel}</th>
                <th>Time</th>
              </tr>
            </thead>
            <tbody>
              {_.map(bidList, (bid) => {
                return (
                  <tr key={bid.id} className={`qa-auction-bid-${bid.id}`}>
                    <td className="qa-auction-bid-amount">${formatPrice(bid.amount)}</td>
                    <td>{formatTime(bid.time_entered)}</td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      );
    }
    else {
      return(
        <div className="box">
          <h3 className="box__header box__header--bordered">Your Bid History</h3>
          <div className="auction-table-placeholder">
            <i>You have not bid on this auction</i>
          </div>
        </div>
      );
    }
};

export default SupplierBidList;
