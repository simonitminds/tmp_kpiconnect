import React from 'react';
import _ from 'lodash';
import { formatPrice } from '../../../../utilities';
import CheckBoxField from '../../../check-box-field';
import MediaQuery from 'react-responsive';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import BidTag from '../../common/bid-tag';

class BiddingFormProduct extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      bidEstimate: '—',
      minBidEstimate: '—'
    }
  }

  handleBidInputChange(ev) {
    this.props.onUpdate;
    this.calculateBidEstimate(ev);
    this.maybePadWithZero(ev);
  }

  calculateBidEstimate(ev) {
    let estimate;
    if (ev.target.value) {
      estimate = `$${formatPrice(parseFloat(ev.target.value) + this.props.currentIndexPrice)}`;
    } else {
      estimate = '—';
    }
    switch(ev.target.name) {
      case "amount":
        this.setState({
          bidEstimate: estimate
        })
      case "min_amount":
        this.setState({
          minBidEstimate: estimate
        })
    }
  }
  maybePadWithZero(ev) {
    let value = ev.target.value;
    if (_.startsWith(value, '.')) {
      ev.target.value = '0' + value
    } else if (_.startsWith(value, '-') && _.startsWith(value, '.', 1)) {
      ev.target.value = '-0' + _.trim(value, '-')
    }
  }

  render() {
    const {fuel, auctionPayload, onRevoke, onUpdate, supplierId} = this.props;

    const {id: fuelId, name} = fuel;
    const fuelQuantity = _.get(auctionPayload, 'auction.fuel_quantity');

    const auctionType = _.get(auctionPayload.auction, 'type');

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
              <BidTag bid={lowestBid} title="Bid to Beat" highlightOwn={hasLowestBid} auctionType={auctionType} />
            </div>
          </div>
          <div className="column">
            <div className="columns is-desktop">
              <div className="column">
                <div className="field">
                  <label className="label" htmlFor="bid">Bid Amount</label>
                  <div className={`control auction-bidding__input has-icons-left ${currentIndexPrice ? 'has-input-add-right' : ''}`}>
                    <span className="icon is-small is-left"><FontAwesomeIcon icon="dollar-sign" /></span>
                    <input
                      type="number"
                      step="0.25"
                      className="input qa-auction-bid-amount"
                      id="bid"
                      name="amount"
                      onChange={this.handleBidInputChange.bind(this)}
                      data-fuel-input
                      data-fuel={fuelId}
                    />
                    { currentIndexPrice &&
                      <span className="input-add is-right has-text-gray-3">(Est: {this.state.bidEstimate})</span>
                    }
                  </div>
                </div>
              </div>
              <div className="column">
                <div className="field">
                  <label className="label" htmlFor="bid">Minimum Bid {auctionPayload.type}</label>
                  <div className={`control auction-bidding__input has-icons-left ${currentIndexPrice ? 'has-input-add-right' : ''}`}>
                    <input
                      type="number"
                      step="0.25"
                      className="input qa-auction-bid-min_amount"
                      id="minimumBid"
                      name="min_amount"
                      onChange={this.handleBidInputChange.bind(this)}
                      data-fuel-input
                      data-fuel={fuelId}
                    />
                    { currentIndexPrice &&
                      <span className="input-add is-right has-text-gray-3">(Est: {this.state.minBidEstimate})</span>
                    }
                    <span className="icon is-small is-left"><FontAwesomeIcon icon="dollar-sign" /></span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  }
};

export default BiddingFormProduct;
