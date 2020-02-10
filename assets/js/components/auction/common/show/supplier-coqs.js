import React from 'react';
import _ from 'lodash';
import COQSubmission from './coq-submission';

const SupplierCOQs = (props) => {
  const {auctionPayload, supplierId, delivered, fuelSuppliers} = props;
  const auctionState = _.get(auctionPayload, 'status');
  const validAuctionState = auctionState === 'pending' || auctionState === 'open';
  const supplierCOQs = _.chain(auctionPayload).get('auction.auction_supplier_coqs').filter(['delivered', delivered]).value();
  const auction = _.get(auctionPayload, 'auction');
  let fuels = _.get(auction, "auction_vessel_fuels", null);
  if (fuels) {
    fuels = _.map(fuels, "fuel");
  } else {
    fuels = [auction.fuel];
  }

  const renderCOQs = () => {
    return fuels.map((fuel) => {
      const fuelSupplier = supplierId ? parseInt(supplierId) : fuelSuppliers[fuel.id];
      const supplierCOQ = _.find(supplierCOQs, { 'fuel_id': fuel.id, 'supplier_id': fuelSupplier });
      if (fuelSupplier) {
        return <COQSubmission {...props} key={`${fuelSupplier}-${fuel.id}`} supplierId={fuelSupplier} fuel={fuel} supplierCOQ={supplierCOQ} />;
      } else {
        return '';
      }
    })
  }

  const renderCOQComponent = () => {
    if ((window.isAdmin && !window.isImpersonating) || (validAuctionState || delivered) || (!validAuctionState && supplierCOQs.length != 0)) {
      if (delivered) {
        return renderCOQs()
      } else {
        return (
          <div className="box has-margin-bottom-md has-padding-bottom-none">
            <div className="box__subsection has-padding-bottom-none">
              <h3 className="box__header">COQs</h3>
              <div className="auction-barging__container">
                { renderCOQs() }
              </div>
            </div>
          </div>
        )
      }
    }
  }

  return (
    <React.Fragment>
      { renderCOQComponent() }
    </React.Fragment>
  )

}

export default SupplierCOQs;
