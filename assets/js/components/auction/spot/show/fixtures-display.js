import _ from 'lodash';
import React from 'react';
import { formatPrice, formatUTCDateTime } from '../../../../utilities';
import CollapsingBargeList from '../../common/show/collapsing-barge-list';
import COQSubmission from '../../common/show/coq-submission';
import ViewCOQ from '../../common/show/view-coq';

const FixturesDisplay = ({ addCOQ, deleteCOQ, auctionPayload, isSupplier }) => {
  const fixtures = _.get(auctionPayload, 'fixtures', []);

  const renderCOQSection = (fixture) => {
    const { id: fixtureId, fuel: fuel, supplier_id: supplierId } = fixture
    const supplierCOQ = _.chain(auctionPayload)
      .get('auction.auction_supplier_coqs')
      .filter({'supplier_id': supplierId, 'delivered': true, 'auction_fixture_id': fixtureId})
      .first()
      .value();


    if (window.isAdmin && !window.isImpersonating || isSupplier) {
      return (
        <COQSubmission
          auctionPayload={auctionPayload}
          addCOQ={addCOQ}
          deleteCOQ={deleteCOQ}
          fuel={fuel}
          supplierId={supplierId}
          supplierCOQ={supplierCOQ}
          fixtureId={fixtureId}
          delivered={true}
        />
    );
    } else if (!!supplierCOQ) {
      return (
        <div className="collapsing-barge__barge">
          <div className="container is-fullhd">
            <ViewCOQ supplierCOQ={supplierCOQ} allowedToDelete={false} fuel={fuel} />
          </div>
        </div>
      )
    } else {
      return (
        <div className="container is-fullhd has-margin-top-md has-margin-bottom-md">
          <i><b>No COQ uploaded for delivery</b></i>
        </div>
      )
    }
  }

  const renderFixture = (fixture) => {
    const delivered = _.get(fixture, 'delivered', false)
    const vessel = delivered ? _.get(fixture, 'delivered_vessel.name', '—') : _.get(fixture, 'vessel.name', "—");
    const fuel = delivered ? _.get(fixture, 'delivered_fuel.name', '—') : _.get(fixture, 'fuel.name', "—");
    let quantity = delivered ? _.get(fixture, 'delivered_quantity', "—") : _.get(fixture, 'quantity', '—');
    quantity = quantity == "—" ? quantity : `${quantity} M/T`;
    let price = delivered ? _.get(fixture, 'delivered_price', '—') : _.get(fixture, 'price', "—");
    price = price == "—" ? price : formatPrice(price);
    const supplier = delivered ? _.get(fixture, 'delivered_supplier.name', '—') : _.get(fixture, 'supplier.name', "—");
    let eta = delivered ? _.get(fixture, 'delivered_eta', '—') : _.get(fixture, 'eta', "—");
    eta = eta == "—" ? eta : formatUTCDateTime(eta);
    let etd = delivered ? _.get(fixture, 'delivered_etd', '—') : _.get(fixture, 'etd', "—");
    etd = etd == "—" ? etd : formatUTCDateTime(etd);
    return (
      <tr key={fixture.id} className={`qa-auction-fixture-${fixture.id}`}>
        <td className="qa-auction-fixture-vessel">{vessel}</td>
        <td className="qa-auction-fixture-fuel">{fuel}</td>
        <td className="qa-auction-fixture-quantity">{quantity}</td>
        <td className="qa-auction-fixture-price">{price}</td>
        <td className="qa-auction-fixture-supplier">{supplier}</td>
        <td className="qa-auction-fixture-eta">{eta}</td>
        <td className="qa-auction-fixture-etd">{etd}</td>
        <td className="qa-auction-fixture-delived">{delivered ? 'Delivered' : ''}</td>
      </tr>
    );
  }

  return (
    <div className="fulfillment-options__history">
      <table className="table is-striped">
        <thead>
          <tr><th colSpan="7">Fixtures</th></tr>
        </thead>
        <tbody>{_.map(fixtures, (fixture) => {
          return (
            <React.Fragment>
              {renderFixture(fixture)}
              <tr key={`coq-${fixture.id}`}>
                <td colSpan="8" className="has-padding-top-none">
                  {renderCOQSection(fixture)}
                </td>
              </tr>
            </React.Fragment>
          )
        })}</tbody>
      </table>
    </div>
  );
}

export default FixturesDisplay;
