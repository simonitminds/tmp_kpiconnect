import React from 'react';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import _ from 'lodash';
import { formatTime, formatPrice } from '../../utilities';
import BidTable from './common/bid-table';

function productsForAuction(auctionPayload) {
  const auctionType = _.get(auctionPayload, 'auction.type');
  switch(auctionType) {
    case 'spot':
      return _.chain(auctionPayload)
          .get('auction.auction_vessel_fuels')
          .reduce((acc, vf) => {
            acc[vf.id] = vf;
            return(acc);
          }, {})
          .value();
    case 'forward_fixed':
    case 'formula_related':
      const fuel = _.get(auctionPayload, 'auction.fuel');
      return { [fuel.id]: fuel };
  }
}

const SupplierBidList = ({auctionPayload, buyer}) => {
  const bidList = _.get(auctionPayload, 'bid_history', []);
  const auctionType = _.get(auctionPayload, 'auction.type');
  const products = productsForAuction(auctionPayload);

  const productName = (bid) => {
    const productId = bid.vessel_fuel_id;

    switch(auctionType) {
      case 'spot':
        return `${products[productId].fuel.name} to ${products[productId].vessel.name}`;
      case 'forward_fixed':
      case 'formula_related':
        return `${products[productId].name}`;
    }
  }

  if(bidList.length > 0) {
    return(
      <div className="qa-supplier-bid-history box has-margin-top-md">
        <h3 className="box__header box__header--bordered">Your Bid History</h3>
        <BidTable
          className="table--supplier-bid-history qa-auction-bidlist"
          bids={bidList}
          columns={["product", "amount", "time_entered"]}
          headers={["Product", "Amount", "Time"]}
          showMinAmounts={true}
        />
      </div>
    );
  }
  else {
    return(
      <div className="qa-supplier-bid-history box">
        <h3 className="box__header box__header--bordered">Your Bid History</h3>
        <div className="auction-table-placeholder">
          <i>You have not bid on this auction</i>
        </div>
      </div>
    );
  }
};

export default SupplierBidList;
