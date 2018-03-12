import React from 'react';
import _ from 'lodash';
import { formatTime } from '../../utilities';

const BuyerWinningBid = ({auction}) => {
  const fuel = _.get(auction, 'fuel.name');
  const winnningBidList = _.get(auction, 'state.winning_bid', []);
  const winnningBidListDisplay = () => {
    if (winnningBidList.length > 0) {
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
            {_.map(winnningBidList, (bid) => {
              return (
                <tr key={bid.id} className={`qa-auction-winning-bid-${bid.id}`}>
                  <td className="qa-auction-winning-bid-supplier">{bid.supplier}</td>
                  <td className="qa-auction-winning-bid-amount">${bid.amount}</td>
                  <td>{formatTime(bid.time_entered)}</td>
                </tr>
              );
            })}
          </tbody>
        </table>
      );
    } else {
      return <i>No bids placed</i>;
    }
  }

  return(
    <div className="box">
      <div className="box__subsection">
        <h3 className="box__header box__header--bordered">Winning Bid(s)</h3>
        {winnningBidListDisplay()}
      </div>
    </div>
  );
};
export default BuyerWinningBid;
