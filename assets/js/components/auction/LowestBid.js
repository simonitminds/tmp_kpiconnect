import React from 'react';
import _ from 'lodash';

const LowestBid = ({auction}) => {
  const fuel = _.get(auction, 'fuel.name');
  return(
    <div>
      <div className="tabs is-fullwidth is-medium">
        <ul>
          <li className="is-active">
            <h2 className="title is-size-5"><a className="has-text-left">Auction Monitor</a></h2>
          </li>
        </ul>
      </div>
      <div className="box">
        <div className="box__subsection">
          <h3 className="box__header box__header--bordered">Lowest Bid(s)</h3>
          <table className="table is-fullwidth is-striped is-marginless">
            <thead>
              <tr>
                <th>Seller</th>
                <th>{fuel}</th>
                <th>Unit Price</th>
                <th>Time</th>
              </tr>
            </thead>
            <tbody>
              <tr className="is-selected">
                <td> Seller 2</td>
                <td> $380.00</td>
                <td> $380.00</td>
                <td> 12:17</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};
export default LowestBid;
