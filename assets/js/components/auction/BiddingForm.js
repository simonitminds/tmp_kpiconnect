import React from 'react';
import _ from 'lodash';

const BiddingForm = ({auction, formSubmit}) => {
  const fuel = _.get(auction, 'fuel.name');
  return(
    <div className="box box--nested-base box--nested-base--base is-gray-1 has-padding-top-md">
      <form onSubmit={formSubmit.bind(this, auction.id)}>
          <h3 className="title is-size-6 is-uppercase has-margin-top-sm">Place Bid</h3>
  {/*
          <div className="field is-horizontal is-expanded">
            <div className="field-label">
              <div className="control">
                <label className="label" htmlFor="fuel_type">Fuel Type</label>
              </div>
            </div>
            <div className="field-body">
              <div className="control is-expanded">
                <div className="select is-fullwidth">
                  <select className="" name="fuel" id="fuel_type">
                    <option value="">Fuel Type</option>
                    <option value={auction.fuel.id}>{auction.fuel.name}</option>
                  </select>
                </div>
              </div>
            </div>
          </div>
  */}
          <div className="field is-horizontal is-expanded">
            <div className="field-label">
              <div className="control">
                <label className="label" htmlFor="bid">Bid Amount</label>
              </div>
            </div>
            <div className="field-body">
              <div className="control is-expanded has-icons-left">
                <input className="input qa-auction-bid-amount" type="number" id="bid" step="0.25" name="amount" />
                <span className="icon is-small is-left">
                  <i className="fas fa-dollar-sign"></i>
                </span>
              </div>
            </div>
          </div>
  {/*
          <div className="field is-horizontal is-expanded">
            <div className="field-label">
              <div className="control">
                <label className="label" htmlFor="bid">Minimum Bid</label>
              </div>
            </div>
            <div className="field-body">
              <div className="control is-expanded has-icons-left">
                <input className="input" type="number" id="minimumBid" step="0.25" name="min_amount" value="" />
                <span className="icon is-small is-left">
                  <i className="fas fa-dollar-sign"></i>
                </span>
              </div>
            </div>
          </div>
          <div className="field is-horizontal is-expanded">
            <div className="field-label">
              <div className="control">
                <label className="label" htmlFor="expiration">Expiration</label>
              </div>
            </div>
            <div className="field-body">
              <div className="control is-expanded">
                <div className="select is-fullwidth">
                  <select className="" name="expiration" id="expiration">
                    <option value="">None</option>
                    <option value="10">10 mins</option>
                    <option value="15">15 mins</option>
                  </select>
                </div>
              </div>
            </div>
          </div>
          <div className="field is-horizontal is-expanded">
            <div className="field-label">
              <div className="control">
                <label className="label" htmlFor="terms">Credit Terms</label>
              </div>
            </div>
            <div className="field-body">
              <div className="control is-expanded">
                <div className="select is-fullwidth">
                  <select className="" name="credit_terms" id="terms">
                    <option value="">Credit Terms</option>
                    <option value="net30">30 Days from Delivery Date</option>
                  </select>
                </div>
              </div>
            </div>
          </div>
  */}
          <div className="field is-expanded is-grouped is-grouped-right has-margin-top-xs has-margin-bottom-sm">
            <div className="control">
              <button type="submit" className="button is-primary qa-auction-bid-submit">Place Bid</button>
            </div>
          </div>
      </form>
    </div>
  );
};

export default BiddingForm;
