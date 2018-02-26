import React from 'react';
import _ from 'lodash';

const BidList = ({auction}) => {
  const fuel = _.get(auction, 'fuel.name');
  return(
    <div className="box">
      <h3 className="box__header box__header--bordered">Grade Display</h3>
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
          <tr>
            <td> OceanConnect Marine</td>
            <td> $380.25</td>
            <td> $380.25</td>
            <td> 12:16</td>
          </tr>
          <tr>
            <td> OceanConnect Marine</td>
            <td> $380.50</td>
            <td> $380.50</td>
            <td> 12:15</td>
          </tr>
        </tbody>
      </table>
    </div>
  );
};

export default BidList;
