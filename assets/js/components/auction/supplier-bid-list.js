import React from 'react';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import _ from 'lodash';
import { formatTime, formatPrice } from '../../utilities';

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
        <table className="table table--supplier-bid-history is-fullwidth is-striped is-marginless qa-auction-bidlist">
          <thead>
            <tr>
              <th>Product</th>
              <th>Amount </th>
              <th>Time</th>
            </tr>
          </thead>
          <tbody>
            {_.map(bidList, (bid) => {
              const {id, amount, min_amount, vessel_fuel_id, is_traded_bid, time_entered} = bid;
              return (
                <tr key={id} className={`qa-auction-bid-${id}`}>
                  <td className="qa-auction-bid-product">{productName(bid)}</td>
                  <td className="qa-auction-bid-amount">
                    <span className="auction__bid-amount">${formatPrice(amount)}</span>
                    { min_amount &&
                      <i className="has-text-gray-4"> (Min: ${formatPrice(min_amount)})</i>
                    }
                    <span className="qa-auction-bid-is_traded_bid">{is_traded_bid &&
                      <span className="auction__traded-bid-tag">
                        <span action-label="Traded Bid" className="auction__traded-bid-marker">
                          <FontAwesomeIcon icon="exchange-alt" />
                        </span>
                        <span className="has-padding-left-sm">Traded Bid</span>
                      </span>}
                    </span>
                  </td>
                  <td>({formatTime(time_entered)})</td>
                </tr>
              );
            })}
          </tbody>
        </table>
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
