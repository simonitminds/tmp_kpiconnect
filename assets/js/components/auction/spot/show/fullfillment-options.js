import _ from 'lodash';
import React from 'react';
import FixturesDisplay from './fixtures-display';
import ClaimsDisplay from './claims-display';
import SupplierCOQs from '../../common/show/supplier-coqs';
import ViewCOQ from '../../common/show/view-coq';

const FullfillmentOptions = ({addCOQ, deleteCOQ, auctionPayload, isSupplier, supplierId}) => {
  const auctionID = _.get(auctionPayload, 'auction.id')
  const fixtures = _.get(auctionPayload, 'fixtures');
  const fuelSuppliers = _.reduce(fixtures, (result, fixture) => {
    result[fixture.fuel_id] ? result : result[fixture.fuel_id] = fixture.supplier_id;
    return result
  }, {});
  const fuels = _.get(auctionPayload, 'auction.fuels');
  const displayOrderStatus = () => {
    if (_.every(fixtures, {delivered: false})) {
      return 'Pre-Delivery';
    } else if (_.every(fixtures, {delivered: true})) {
      return 'Post-Delivery';
    } else {
      return 'Partial-Delivery';
    }
  }

  const renderCOQSection = () => {
    if ((window.isAdmin && !window.isImpersonating) || isSupplier) {
      if (_.isEmpty(fuelSuppliers)) {
        return "";
      } else {
        return (
          <div className="has-margin-top-md">
            <h3 className="box__header">Delivered COQs</h3>
            <SupplierCOQs
              addCOQ={addCOQ}
              deleteCOQ={deleteCOQ}
              auctionPayload={auctionPayload}
              fuelSuppliers={fuelSuppliers}
              delivered={true}
            />
          </div>
        )
      }
    } else {
      const supplierCOQs = _.chain(auctionPayload)
        .get('auction.auction_supplier_coqs')
        .filter(['delivered', true])
        .value();
      return supplierCOQs.map((supplierCOQ) => {
        const fuelId = _.get(supplierCOQ, 'fuel_id');
        const fuel = _.chain(fuels).filter(['id', fuelId]).first().value();
        return (
          <div className="has-margin-top-md">
            <h3 className="box__header">Delivered COQs</h3>
            <div className="collapsing-barge__barge" key={fuelId}>
              <div className="container is-fullhd">
                <ViewCOQ supplierCOQ={supplierCOQ} allowedToDelete={false} fuel={fuel}/>
              </div>
            </div>
          </div>
        );
      })
    }
  }

  return(
    <div className="box fulfillment-options">
        <h2>Order Status: {displayOrderStatus()}</h2>
        { !isSupplier &&
          <div className="fulfillment-options__actions">
            <h3 className="has-margin-right-md is-inline-block">Options</h3>
            <a href={`/auctions/${auctionId}/claims/new`} className="button is-primary qa-auction-claims-place_claim">Place Claim</a>
          </div>
        }
      { renderCOQSection() }
      <FixturesDisplay auctionPayload={auctionPayload} />
      <ClaimsDisplay auctionPayload={auctionPayload} isSupplier={isSupplier} />
    </div>
  );
};

export default FullfillmentOptions;
