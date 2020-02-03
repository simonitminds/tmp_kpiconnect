import React from 'react';
import _ from 'lodash';
import COQSubmission from './coq-submission';

const SupplierCOQs = (props) => {
  const {auctionPayload, supplierId} = props;
  const auctionState = _.get(auctionPayload, 'status');
  const validAuctionState = auctionState === 'pending' || auctionState === 'open';
  const supplierCOQs = _.get(auction, 'auction_supplier_coqs');
  const auction = _.get(auctionPayload, 'auction');
  let fuels = _.get(auction, "auction_vessel_fuels", null);
  if (fuels) {
    fuels = _.map(fuels, "fuel");
  } else {
    fuels = [auction.fuel];
  }

  const renderCOQComponent = () => {
    if ((window.isAdmin && !window.isImpersonating) || validAuctionState || (!validAuctionState && supplierCOQs.length != 0) ) {
      return (
        <div className="box has-margin-bottom-md has-padding-bottom-none">
          <div className="box__subsection has-padding-bottom-none">
            <h3 className="box__header">COQs</h3>
            <div className="qa-coqs">
              {
                fuels.map((fuel) => {
                  const supplierCOQ = _.find(supplierCOQs, { 'fuel_id': fuel.id, 'supplier_id': parseInt(supplierId) });
                  return (
                    <COQSubmission {...props} fuel={fuel} supplierCOQ={supplierCOQ} />
                  )
                })
              }
            </div>
          </div>
        </div>
      )
    }
  }

  return (
    <div>
      { renderCOQComponent() }
    </div>
  )

}

export default SupplierCOQs;
