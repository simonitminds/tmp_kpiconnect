import React from 'react';
import _ from 'lodash';
import MediaQuery from 'react-responsive';
import CollapsibleSection from './collapsible-section';

const BiddingForm = ({auctionPayload, formSubmit}) => {
  const auction = auctionPayload.auction;
  const minimumBidAmount = _.get(auctionPayload, 'state.minimum_bids[0].min_amount');
  const fuel = _.get(auction, 'fuel.name');
  return(
    <div className="auction-bidding box box--nested-base box--nested-base--base">
      <MediaQuery query="(min-width: 769px)">
        <form onSubmit={formSubmit.bind(this, auction.id)}>
          <h3 className="title is-size-6 is-uppercase has-margin-top-sm">Place Bid</h3>
          <div className="field is-horizontal is-expanded">
            <div className="field-label">
              <div className="control">
                <label className="label" htmlFor="bid">Bid Amount</label>
              </div>
            </div>
          </div>
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
          <div className="field is-horizontal is-expanded">
            <div className="field-label">
              <div className="control">
                <label className="label" htmlFor="bid">Minimum Bid</label>
              </div>
            </div>
            <div className="field-body">
              <div className="control is-expanded has-icons-left">
                <input
                  className="input qa-auction-bid-min_amount"
                  type="number"
                  id="minimumBid"
                  step="0.25"
                  min="0"
                  name="min_amount"
                  defaultValue={minimumBidAmount} />
                <span className="icon is-small is-left">
                  <i className="fas fa-dollar-sign"></i>
                </span>
              </div>
            </div>
          </div>
          <div className="field is-horizontal is-expanded">
            <div className="field is-expanded is-grouped is-grouped-right has-margin-top-xs has-margin-bottom-sm">
              <div className="control">
                <button type="submit" className="button is-primary qa-auction-bid-submit">Place Bid</button>
              </div>
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
        </CollapsibleSection>
      </MediaQuery>
    </div>
  );
};

export default BiddingForm;
