import React from 'react';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import _ from 'lodash';
import { formatTime, formatPrice } from '../../../../utilities';
import BidTable from '../../common/show/bid-table';

const SupplierBidList = ({auctionPayload, buyer}) => {
  const bidList = _.get(auctionPayload, 'bid_history', []);
  const auctionType = _.get(auctionPayload, 'auction.type');
  const fuel = _.get(auctionPayload, 'auction.fuel');
  const fuelQuantity = _.get(auctionPayload, 'auction.fuel_quantity')
  const productName = `${_.get(fuel, 'name')} ${fuelQuantity} M/T/Month`

  if(bidList.length > 0) {
    return(
      <div className="qa-supplier-bid-history box has-margin-top-md">
        <h3 className="box__header box__header--bordered">Your Bid History</h3>
        <BidTable
          className="table--supplier-bid-history qa-auction-bidlist"
          bids={bidList}
          columns={["product", "amount", "time_entered"]}
          headers={[productName, "Amount", "Time"]}
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

