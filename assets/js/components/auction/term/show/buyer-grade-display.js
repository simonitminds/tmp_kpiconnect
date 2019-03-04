import React from 'react';
import _ from 'lodash';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { formatTime, formatPrice } from '../../../../utilities';
import BidTable from '../../common/show/bid-table';

const BuyerGradeDisplay = ({auctionPayload, buyer}) => {
  const fuel = _.get(auctionPayload, 'auction.fuel');
  const fuelQuantity = _.get(auctionPayload, 'auction.fuel_quantity');

  const productBids = _.get(auctionPayload, 'product_bids');
  const products = _.keys(productBids);

  const bidList = _.chain(productBids)
    .map('lowest_bids')
    .flatten()
    .orderBy(['amount', 'time_entered'], ['asc', 'desc'])
    .value();

  if(bidList.length > 0) {
    return(
      <div className="box qa-buyer-bid-history">
        <h3 className="box__header box__header--bordered">Grade Display</h3>
        { _.map(products, (fuelId) => {
            const lowestBids = productBids[fuelId].lowest_bids;
          const productName = `${_.get(fuel, 'name')} × ${fuelQuantity} MT/month`

            return <BidTable
              key={fuelId}
              className="table--grade-display"
              bids={lowestBids}
              columns={["supplier", "amount", "time_entered"]}
              headers={[productName, "Price", "Time"]}
              showMinAmount={false}
            />;
          })
        }
      </div>
    );
  } else {
    return(
      <div className="box">
        <h3 className="box__header box__header--bordered">Grade Display</h3>
        <div className="auction-table-placeholder">
          <i>No bids have been placed on this auction</i>
        </div>
      </div>
    );
  }
};

export default BuyerGradeDisplay;
