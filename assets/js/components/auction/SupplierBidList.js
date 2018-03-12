import React from 'react';
import _ from 'lodash';
import { formatTime } from '../../utilities';

const SupplierBidList = ({auction, buyer}) => {
  const fuel = _.get(auction, 'fuel.name');
  const bidList = _.get(auction, 'bid_list', []);
  const winningBidIds = _.chain(auction)
    .get('state.winning_bid', [])
    .map('id')
    .value();

  return(
    <div className="box">
      <h3 className="box__header box__header--bordered">Grade Display</h3>
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
                <td>${bid.amount}</td>
                <td>{formatTime(bid.time_entered)}</td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
};

export default SupplierBidList;
