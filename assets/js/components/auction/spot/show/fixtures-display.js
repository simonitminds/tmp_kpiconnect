import _ from 'lodash';
import React from 'react';
import { formatPrice, formatUTCDateTime } from '../../../../utilities';

const FixturesDisplay = ({auctionPayload}) => {
  const fixtures = _.get(auctionPayload, 'fixtures', []);

  return(
    <div className="fulfillment-options__history">
      <table className="table is-striped">
        <thead>
          <tr><th colSpan="7">Fixtures</th></tr>
        </thead>
        <tbody>
          { _.map(fixtures, (fixture) => {
              const vessel = _.get(fixture, 'vessel.name', "—");
              const fuel = _.get(fixture, 'fuel.name', "—");
              let quantity = _.get(fixture, 'quantity', "—");
              quantity = quantity == "—" ? quantity : `${quantity} M/T`;
              let price = _.get(fixture, 'price', "—");
              price = price == "—" ? price : formatPrice(price);
              const supplier = _.get(fixture, 'supplier.name', "—");
              let eta = _.get(fixture, 'eta', "—");
              eta = eta == "—" ? eta : formatUTCDateTime(eta);
              let etd = _.get(fixture, 'etd', "—");
              etd = etd == "—" ? etd : formatUTCDateTime(etd);
              return(
                <tr key={fixture.id} className={`qa-auction-fixture-${fixture.id}`}>
                  <td className="qa-auction-fixture-vessel">{vessel}</td>
                  <td className="qa-auction-fixture-fuel">{fuel}</td>
                  <td className="qa-auction-fixture-quantity">{quantity}</td>
                  <td className="qa-auction-fixture-price">{price}</td>
                  <td className="qa-auction-fixture-supplier">{supplier}</td>
                  <td className="qa-auction-fixture-eta">{eta}</td>
                  <td className="qa-auction-fixture-etd">{etd}</td>
                </tr>
              );
            })
          }
        </tbody>
      </table>
    </div>
  );
};

export default FixturesDisplay;
