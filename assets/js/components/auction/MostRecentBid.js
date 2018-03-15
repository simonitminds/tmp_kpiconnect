import React from 'react';
import _ from 'lodash';
import { formatTime } from '../../utilities';

const MostRecentBid = ({auction}) => {
  const fuel = _.get(auction, 'fuel.name');
  const mostRecentBid = _.chain(auction)
    .get('bidlist', [])
    .first()
    .value();
  const mostRecentBidDisplay = () => {
    if (_.get(mostRecentBid, 'amount')) {
      return (
        <table className="table is-fullwidth is-striped is-marginless">
          <thead>
            <tr>
              <th>{fuel}</th>
              <th>Time</th>
            </tr>
          </thead>
          <tbody>
            <tr className="is-gray-1">
              <td>{mostRecentBid.amount}</td>
              <td>{formatTime(mostRecentBid.time_entered)}</td>
            </tr>
          </tbody>
        </table>
      );
    } else {
      return <i>No bid placed</i>;
    }
  }

  return(
    <div>
      <h3 className="box__header box__header--bordered">Your Most Recent Bid</h3>
      {mostRecentBidDisplay()}
    </div>
  );
};

export default MostRecentBid;
