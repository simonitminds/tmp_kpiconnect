import React from 'react';
import _ from 'lodash';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { formatTime, formatPrice } from '../../../../utilities';
import BidTable from '../../common/show/bid-table';

const BuyerGradeDisplay = ({auctionPayload, buyer}) => {
  const vesselFuels = _.chain(auctionPayload)
    .get('auction.auction_vessel_fuels')
    .reduce((acc, vesselFuel) => {
      acc[vesselFuel.id] = vesselFuel;
      return(acc);
    }, {})
    .value();

  const productBids = _.get(auctionPayload, 'product_bids');
  const products = _.chain(productBids)
    .keys()
    .sortBy([
      (vfId) => vesselFuels[vfId].fuel_id,
      (vfId) => vesselFuels[vfId].vessel_id
    ])
    .value();
  const bidList = _.chain(productBids)
    .map('lowest_bids')
    .flatten()
    .orderBy(['amount', 'time_entered'], ['asc', 'desc'])
    .value();
  const { status } = auctionPayload;

  if(bidList.length > 0) {
    return(
      <div className="box qa-buyer-bid-history">
        <h3 className="box__header box__header--bordered">Grade Display</h3>
        { _.map(products, (vfId) => {
            const lowestBids = productBids[vfId].lowest_bids;
            const productName = `${vesselFuels[vfId].fuel.name} for ${vesselFuels[vfId].vessel.name}`;

            return <BidTable
              key={vfId}
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
          { status == 'pending' ?
          <i>Any bids placed during the pending period will display upon auction start</i> :
          <i>No bids have been placed on this auction</i>
          }
        </div>
      </div>
    );
  }
};

export default BuyerGradeDisplay;
