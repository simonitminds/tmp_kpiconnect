import React from 'react';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import _ from 'lodash';
import k from 'react-responsive';
import CollapsibleSection from '../../common/collapsible-section';
import { formatPrice } from '../../../../utilities';
import CheckBoxField from '../../../check-box-field';
import MediaQuery from 'react-responsive';
import BiddingFormProduct from './bidding-form-product';
import BiddingFormComment from './bidding-form-comment';

class BiddingForm extends React.Component {
  constructor(props){
    super(props);
    const is_traded_bid = _.chain(props.auctionPayload)
                           .get('bid_history')
                           .filter('active')
                           .some('is_traded_bid')
                           .value();
    this.state = {
      tradedBidChecked: is_traded_bid
    }
  }

  handleTradedBidCheckboxChange(ev) {
    this.setState({
      tradedBidChecked: ev.target.checked
    });
  }

  createFormData(ev) {
    const bidElements = _.reject(ev.target.elements, (e) => !e.dataset.fuelInput);

    const fuelBids = _.reduce(bidElements, (acc, e) => {
      acc[e.dataset.fuel] = acc[e.dataset.fuel] || {};
      switch(e.type) {
        case 'checkbox':
          acc[e.dataset.fuel][e.name] = e.checked;
          break;

        default:
          acc[e.dataset.fuel][e.name] = e.value;
          break;
      }
      return acc;
    }, {});

    const elements = ev.target.elements;
    _.forEach(elements, (e) => e.value = "");

    const tradedBid = elements && elements.is_traded_bid && elements.is_traded_bid.checked;

    const formData = {'bids': fuelBids, 'is_traded_bid': tradedBid};
    return (formData);
  }

  submitForm(ev) {
    ev.preventDefault();
    const {auctionPayload, formSubmit} = this.props;
    const {auction} = auctionPayload;
    const formData = this.createFormData(ev);
    formSubmit(auction.id, formData);
  }

  render() {
    const {
      auctionPayload,
      revokeBid,
      supplierId
    } = this.props;

    const auction = _.get(auctionPayload, 'auction');
    const fuel = _.get(auction, 'fuel');
    const auctionStatus = _.get(auctionPayload, 'status');
    const credit_margin_amount = formatPrice(_.get(auction, 'buyer.credit_margin_amount'))
    const is_traded_bid_allowed = _.get(auction, 'is_traded_bid_allowed')

    return (
      <div className={`auction-bidding ${auctionStatus == 'pending'? `auction-bidding--pending` : ``} box box--nested-base`}>
        <MediaQuery query="(min-width: 769px)">
          <form onSubmit={this.submitForm.bind(this)}>
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
                      defaultChecked={this.state.tradedBidChecked}
                      onChange={this.handleTradedBidCheckboxChange.bind(this)}
                      opts={{labelClass: 'label is-capitalized is-inline-block has-margin-left-sm'}}
                    />
                    <i>Buyer's Credit Margin with OCM: $<span className="qa-auction-credit_margin_amount">{credit_margin_amount}</span></i>
                  </div>
                </div>
              }
              { this.state.tradedBidChecked &&
                <div className="traded-bid-help-text notification is-turquoise">
                  <FontAwesomeIcon icon="info-circle" className="is-inline-block has-margin-right-sm" /> Add the above credit margin to your baseline price when placing your bid
                </div>
              }
              <BiddingFormProduct
                fuel={fuel}
                auctionPayload={auctionPayload}
                supplierId={supplierId}
                onRevoke={revokeBid} />
              <BiddingFormComment
                fuel={fuel}
                auctionPayload={auctionPayload} />
            </div>
            <div className="field is-horizontal is-expanded">
              <div className="field is-expanded is-grouped is-grouped-right has-margin-top-xs has-margin-bottom-sm has-margin-left-auto">
                <div className="control">
                  <button type="submit" className="button is-primary has-margin-top-sm qa-auction-bid-submit">Place Bid</button>
                </div>
              </div>
            </div>
          </form>
        </MediaQuery>
      </div>
    );
  }
}

export default BiddingForm;
