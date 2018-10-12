import React from 'react';
import _ from 'lodash';
import MediaQuery from 'react-responsive';
import CollapsibleSection from './collapsible-section';
import { formatPrice } from '../../utilities';
import CheckBoxField from '../check-box-field';

const BiddingForm = ({auctionPayload, formSubmit, barges}) => {
  const auction = auctionPayload.auction;
  const auctionState = auctionPayload.status;
  const products = _.sortBy(auction.fuels, 'id');
  const credit_margin_amount = formatPrice(_.get(auction, 'buyer.credit_margin_amount'))
  const is_traded_bid_allowed = _.get(auction, 'is_traded_bid_allowed')
  const is_traded_bid = _.get(auctionPayload, 'bid_history[0].is_traded_bid');

  const renderProduct = ({id, name}, auctionPayload) => {
    const currentBidAmount = _.get(auctionPayload, `product_bids[${id}].bid_history[0].amount`);
    const minimumBidAmount = _.get(auctionPayload, `product_bids[${id}].bid_history[0].min_amount`);
    const vesselFuels = _.chain(auctionPayload)
      .get('auction.auction_vessel_fuels')
      .filter((avf) => avf.fuel_id == id)
      .value();
    const totalQuantity = _.sumBy(vesselFuels, (vf) => vf.quantity);

    return(
      <div className="auction-bidding__product-group columns is-desktop" key={id}>
        <div className="column is-one-quarter-desktop"><strong>{name}</strong><br/><span className="has-text-gray-3">&times; {totalQuantity} MT </span></div>
        <div className="column">
          <div className="columns is-desktop">
            <div className="column">
              <div className="field is-horizontal is-expanded">
                <div className="field-label">
                  <div className="control"><label className="label" htmlFor="bid">Bid Amount<br/><span className="auction-bidding__label-addendum">Current: {currentBidAmount ? `$` + formatPrice(currentBidAmount) : '—'}</span></label></div>
                </div>
                <div className="field-body auction-bidding__input">
                  <div className="control is-expanded has-icons-left"><input type="number" step="0.25" min="0" className="input qa-auction-bid-amount" id="bid" name="amount" data-product={id}/><span className="icon is-small is-left"><i className="fas fa-dollar-sign"></i></span></div>
                </div>
              </div>
            </div>
            <div className="column">
              <div className="field is-horizontal is-expanded">
                <div className="field-label">
                  <div className="control"><label className="label" htmlFor="bid">Minimum Bid<br/><span className="auction-bidding__label-addendum">Current: {minimumBidAmount ? `$` + formatPrice(minimumBidAmount) : '—'}</span></label></div>
                </div>
                <div className="field-body auction-bidding__input">
                  <div className="control is-expanded has-icons-left"><input type="number" step="0.25" min="0" className="input qa-auction-bid-min_amount" id="minimumBid" name="min_amount" data-product={id}/><span className="icon is-small is-left"><i className="fas fa-dollar-sign"></i></span></div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  };

  return(
    <div className={`auction-bidding ${auctionState == 'pending' ? 'auction-bidding--pending':''} box box--nested-base box--nested-base--base`}>
      <form onSubmit={formSubmit.bind(this, auction.id)}>
        <h3 className="auction-bidding__title title is-size-6 is-uppercase has-margin-top-sm">Place Bid</h3>
        { products.map((product) => renderProduct(product, auctionPayload)) }

        {(auction.split_bid_allowed === true) &&
          <div className="field field--offset is-horizontal">
            <label className="checkbox">
              <input className="has-margin-right-sm" type="checkbox" />
                <strong>Do not split my bid</strong>
            </label>
          </div>
        }
        { (is_traded_bid_allowed === true) &&
          <div className="field field--ribbon is-horizontal">
            <div className="field-label"></div>
            <div className="field-body">
              <CheckBoxField
                model={'auction-bid'}
                field={'is_traded_bid'}
                labelText={'mark as traded bid'}
                value={is_traded_bid}
                opts={{labelClass: 'label is-capitalized is-inline-block has-margin-left-sm'}}
              />
            </div>
          <i>Buyer's Credit Margin with OCM: $<span className="qa-auction-credit_margin_amount">{credit_margin_amount}</span></i>
          </div>
        }
        <div className="field is-horizontal is-expanded">
          <div className="field is-expanded is-grouped is-grouped-right has-margin-top-xs has-margin-bottom-sm has-margin-left-auto">
            <div className="control"><button type="submit" className="button is-primary qa-auction-bid-submit">Place Bid</button></div>
          </div>
        </div>
      </form>
    </div>
  );
}
export default BiddingForm;
