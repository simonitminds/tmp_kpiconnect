import React from 'react';
import _ from 'lodash';
import k from 'react-responsive';
import CollapsibleSection from './collapsible-section';
import { formatPrice } from '../../utilities';
import CheckBoxField from '../check-box-field';
import MediaQuery from 'react-responsive';


const BiddingForm = ({auctionPayload, formSubmit, revokeBid, barges}) => {
  const auction = auctionPayload.auction;
  const auctionState = auctionPayload.status;
  const products = _.sortBy(auction.fuels, 'id');
  const credit_margin_amount = formatPrice(_.get(auction, 'buyer.credit_margin_amount'));
  const is_traded_bid_allowed = _.get(auction, 'is_traded_bid_allowed')
  const is_traded_bid = _.get(auctionPayload, 'bid_history[0].is_traded_bid');

  const renderProduct = ({id: productId, name}, auctionPayload) => {
    const existingBid = _.chain(auctionPayload)
      .get(`product_bids[${productId}].bid_history`)
      .filter('active')
      .first()
      .value();
    const currentBidAmount = _.get(existingBid, `amount`);
    const minimumBidAmount = _.get(existingBid, `min_amount`);
    const allowSplit = _.get(existingBid, 'allow_split', true);
    const vesselFuels = _.chain(auctionPayload)
      .get('auction.auction_vessel_fuels')
      .filter((avf) => avf.fuel_id == productId)
      .value();
    const totalQuantity = _.sumBy(vesselFuels, (vf) => vf.quantity);
    const confirmBidCancellation = (ev) => {
      ev.preventDefault();
      return confirm('Are you sure you want to cancel your bid for this product?') ? revokeBid(auction.id, productId) : false;
    };


    return(
      <div className="auction-bidding__product-group columns is-desktop" key={productId}>
        <div className="column is-one-quarter-desktop">
          <strong>{name}</strong><br/>
          <span className="has-text-gray-3">&times; {totalQuantity} MT </span>
          { existingBid
            ? <div className="tags has-addons has-margin-top-xs">
                <div className="tag is-success"><i className="fas fa-check"></i></div>
                <div className="tag revoke-bid__status is-white">Bid Active</div>
                <span className={`tag revoke-bid__button qa-auction-product-${productId}-revoke`} onClick={confirmBidCancellation} tabIndex="-1"><i className="fas fa-minus"></i></span>
              </div>
            : <div className="tags has-addons has-margin-top-xs">
                <div className="tag is-gray-3"><i className="fas fa-times"></i></div>
                <div className="tag is-white revoke-bid__status">No Active Bid</div>
              </div>
          }
        </div>
        <div className="column">
          <div className="columns is-desktop">
            <div className="column">
              <div className="field">
                <label className="label" htmlFor="bid">Bid Amount</label>
                <div className="control auction-bidding__input has-icons-left">
                  <span className="icon is-small is-left"><i className="fas fa-dollar-sign"></i></span>
                  <input type="number" step="0.25" min="0" className="input qa-auction-bid-amount" id="bid" name="amount" data-product={productId}/>
                </div>
                <p className="help auction-bidding__label-addendum">Current: {currentBidAmount ? `$` + formatPrice(currentBidAmount) : '—'}</p>
              </div>
            </div>
            <div className="column">
              <div className="field">
                <label className="label" htmlFor="bid">Minimum Bid</label>
                <div className="control auction-bidding__input has-icons-left">
                  <input type="number" step="0.25" min="0" className="input qa-auction-bid-min_amount" id="minimumBid" name="min_amount" data-product={productId}/>
                  <span className="icon is-small is-left"><i className="fas fa-dollar-sign"></i></span>
                </div>
                <p className="help auction-bidding__label-addendum">Current: {minimumBidAmount ? `$` + formatPrice(minimumBidAmount) : '—'}</p>
              </div>
            </div>
          </div>
        </div>
        <div className="column is-narrow">
          <label className="checkbox">
            <input type="checkbox" className="qa-auction-bid-allow_split" name="allow_split" defaultChecked={allowSplit} data-product={productId}/> Split?
          </label>
        </div>
      </div>
    );
  };

  return(
    <div className={`auction-bidding ${auctionState == 'pending' ? 'auction-bidding--pending':''} box box--nested-base box--nested-base--base`}>
      <MediaQuery query="(min-width: 769px)">
        <form onSubmit={formSubmit.bind(this, auction.id)}>
          <h3 className="auction-bidding__title title is-size-6 is-uppercase has-margin-top-sm">Place Bid</h3>
          <div className="auction-bidding__form-body">
            { (is_traded_bid_allowed === true) &&
              <div className="field field--ribbon is-horizontal">
                <div className="field-label"></div>
                <div className="field-body field-body--wrapped">
                  <CheckBoxField
                    model={'auction-bid'}
                    field={'is_traded_bid'}
                    labelText={'mark as traded bid'}
                    value={is_traded_bid}
                    opts={{labelClass: 'label is-capitalized is-inline-block has-margin-left-sm'}}
                  />
                  <i>Buyer's Credit Margin with OCM: $<span className="qa-auction-credit_margin_amount">{credit_margin_amount}</span></i>
                </div>
              </div>
            }
            <div className="traded-bid-help-text notification is-turquoise">
              <i className="fas fa-info-circle is-inline-block has-margin-right-sm"></i> Add the above credit margin to your baseline price when placing your bid
            </div>
            { products.map((product) => renderProduct(product, auctionPayload)) }
          </div>

          <div className="field is-horizontal is-expanded">
            <div className="field is-expanded is-grouped is-grouped-right has-margin-top-xs has-margin-bottom-sm has-margin-left-auto">
              <div className="control"><button type="submit" className="button is-primary qa-auction-bid-submit">Place Bid</button></div>
            </div>
          </div>
        </form>
      </MediaQuery>
      <MediaQuery query="(max-width: 768px)">
        <CollapsibleSection
          trigger="Place Bid"
          classParentString="collapsing-auction-bidding"
          open={true}
        >
          <form onSubmit={formSubmit.bind(this, auction.id)}>
            <h3 className="auction-bidding__title title is-size-6 is-uppercase has-margin-top-sm">Place Bid</h3>
            <div className="auction-bidding__form-body">
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

              { products.map((product) => renderProduct(product, auctionPayload)) }
            </div>

            <div className="field is-horizontal is-expanded">
              <div className="field is-expanded is-grouped is-grouped-right has-margin-top-xs has-margin-bottom-sm has-margin-left-auto">
                <div className="control"><button type="submit" className="button is-primary qa-auction-bid-submit">Place Bid</button></div>
              </div>
            </div>
          </form>
        </CollapsibleSection>
      </MediaQuery>
    </div>
  );
}
export default BiddingForm;
