import React from 'react';
import _ from 'lodash';

const MostRecentBid = ({auction}) => {
  const fuel = _.get(auction, 'fuel.name');
  return(
    <div>
      <h3 className="box__header box__header--bordered">Your Most Recent Bid</h3>
      <table className="table is-fullwidth is-striped is-marginless">
        <thead>
          <tr>
            <th>{fuel}</th>
            <th>Unit Price</th>
            <th>Time</th>
          </tr>
        </thead>
        <tbody>
          <tr className="is-gray-1">
            <td> $380.00</td>
            <td> $380.00</td>
            <td> 12:17</td>
          </tr>
        </tbody>
      </table>
    </div>
  );
};

export default MostRecentBid;
