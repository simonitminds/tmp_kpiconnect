import React from 'react';
import _ from 'lodash';
import { formatTime } from '../../utilities';

const BidList = ({auction}) => {
  const fuel = _.get(auction, 'fuel.name');
  const bidList = _.get(auction, 'bidList', []);
  const winningBidIds = _.chain(auction)
    .get('state.winning_bid', [])
    .map('id')
    .value();
  return(
    <div className="box">
      <h3 className="box__header box__header--bordered">Grade Display</h3>
      <table className="table is-fullwidth is-striped is-marginless">
        <thead>
          <tr>
            <th>Seller</th>
            <th>{fuel}</th>
            <th>Time</th>
          </tr>
        </thead>
        <tbody>
          {_.map(bidList, (bid) => {
            return (
              <tr key={bid.id} className={bid.id in winningBidIds ? "is-selected" : ""}>
                <td>{bid.supplier_id}</td>
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

export default BidList;
