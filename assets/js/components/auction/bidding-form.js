import React from 'react';
import _ from 'lodash';

const BiddingForm = ({auction, formSubmit}) => {
  const fuel = _.get(auction, 'fuel.name');
  return(
    <div className="auction-bidding box box--nested-base box--nested-base--base">
      <form onSubmit={formSubmit.bind(this, auction.id)}>
          <h3 className="title is-size-6 is-uppercase has-margin-top-sm">Place Bid</h3>
          <div className="field is-horizontal is-expanded">
            <div className="field-label">
              <div className="control">
                <label className="label" htmlFor="bid">Bid Amount</label>
              </div>
            </div>
            <div className="field-body">
              <div className="control is-expanded has-icons-left">
                <input className="input qa-auction-bid-amount" type="number" id="bid" step="0.25" min="0" name="amount" />
                <span className="icon is-small is-left">
                  <i className="fas fa-dollar-sign"></i>
                </span>
              </div>
            </div>
          </div>
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
