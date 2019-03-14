import React from 'react';
import _ from 'lodash';
import { formatPrice } from '../../../../utilities';
import CheckBoxField from '../../../check-box-field';
import MediaQuery from 'react-responsive';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import BidTag from '../../common/bid-tag';

const BiddingFormProduct = ({fuel, auctionPayload, onRevoke, onUpdate, supplierId}) => {
  const {id: fuelId, name} = fuel;
  const fuelQuantity = _.get(auctionPayload, 'auction.fuel_quantity');

  const currentIndexPrice = _.get(auctionPayload, 'auction.current_index_price', 0.00);

  const lowestBid = _.get(auctionPayload, `product_bids['${fuelId}'].lowest_bids[0]`)

  const hasLowestBid = lowestBid && supplierId && (lowestBid.supplier_id == supplierId);


  return(
    <div className="auction-bidding__product-group has-margin-bottom-md">
      <div className="columns is-desktop has-margin-bottom-xs">
        <div className="column is-one-quarter-desktop">
          <strong>{name}</strong><br/>
          <span className="has-text-gray-3">&times; {fuelQuantity} MT </span><br/>
          { currentIndexPrice &&
            <div className="control control--flex-limit has-margin-top-sm">
              <BidTag bid={currentIndexPrice} indexPrice="true" title="Index Price" />
            </div>
          }
          <div className="control control--flex-limit has-margin-top-sm">
            <BidTag bid={lowestBid} title="Bid to Beat" highlightOwn={hasLowestBid} />
          </div>
        </div>
        <div className="column">
          <div className="columns is-desktop">
            <div className="column">
              <div className="field">
                <label className="label" htmlFor="bid">Bid Amount</label>
                <div className="control auction-bidding__input has-icons-left">
                  <span className="icon is-small is-left"><FontAwesomeIcon icon="dollar-sign" /></span>
                  <input
                    type="number"
                    step="0.25"
                    min="0"
                    className="input qa-auction-bid-amount"
                    id="bid"
                    name="amount"
                    onChange={onUpdate}
                    data-fuel-input
                    data-fuel={fuelId}
                  />
                </div>
              </div>
            </div>
            <div className="column">
              <div className="field">
                <label className="label" htmlFor="bid">Minimum Bid</label>
                <div className="control auction-bidding__input has-icons-left">
                  <input
                    type="number"
                    step="0.25"
                    min="0"
                    className="input qa-auction-bid-min_amount"
                    id="minimumBid"
                    name="min_amount"
                    onChange={onUpdate}
                    data-fuel-input
                    data-fuel={fuelId}
                  />
                  <span className="icon is-small is-left"><FontAwesomeIcon icon="dollar-sign" /></span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default BiddingFormProduct;
