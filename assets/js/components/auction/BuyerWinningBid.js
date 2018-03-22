import React from 'react';
import _ from 'lodash';
import { formatTime, formatPrice } from '../../utilities';

const BuyerWinningBid = ({auction}) => {
  const fuel = _.get(auction, 'fuel.name');
  const winningBidList = _.get(auction, 'state.winning_bids', []);
  const winningBidListDisplay = () => {
    if (winningBidList.length > 0) {
      return (
        <table className="table is-fullwidth is-striped is-marginless">
          <thead>
            <tr>
              <th>Seller</th>
              <th>{fuel}</th>
              <th>Time</th>
            </tr>
          </thead>
          <tbody>
            {_.map(winningBidList, (bid) => {
              return (
                <tr key={bid.id} className={`qa-auction-winning-bid-${bid.id}`}>
                  <td className="qa-auction-winning-bid-supplier">{bid.supplier}</td>
                  <td className="qa-auction-winning-bid-amount">${formatPrice(bid.amount)}</td>
                  <td>{formatTime(bid.time_entered)}</td>
                </tr>
              );
            })}
          </tbody>
        </table>
      );
    } else {
      return <div className="auction-table-placeholder">
        <i>No bids have been placed on this auction</i>
      </div>;
    }
  }

  return(
    <div className="box">
      <div className="box__subsection has-padding-bottom-none">
        <h3 className="box__header box__header--bordered">Winning Bid(s)</h3>
        {winningBidListDisplay()}
      </div>
    </div>
  );
};
export default BuyerWinningBid;
