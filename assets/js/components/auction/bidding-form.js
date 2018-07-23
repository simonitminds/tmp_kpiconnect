import React from 'react';
import _ from 'lodash';
import MediaQuery from 'react-responsive';
import CollapsibleSection from './collapsible-section';
import { formatPrice } from '../../utilities';

const BiddingForm = ({auctionPayload, formSubmit, barges}) => {
  const auction = auctionPayload.auction;
  const auctionState = auctionPayload.status;
  const currentBidAmount = _.get(auctionPayload, 'bid_history[0].amount');
  const minimumBidAmount = _.get(auctionPayload, 'bid_history[0].min_amount');
  const fuel = _.get(auction, 'fuel.name');
  return(
    <div className={`auction-bidding ${auctionState == 'pending' ? 'auction-bidding--pending':''} box box--nested-base box--nested-base--base`}>
      <MediaQuery query="(min-width: 769px)">
        <form onSubmit={formSubmit.bind(this, auction.id)}>
          <h3 className="title is-size-6 is-uppercase has-margin-top-sm">Place Bid</h3>
          <div className="field is-horizontal is-expanded">
            <div className="field-label">
              <div className="control">
                <label className="label" htmlFor="bid">Bid Amount<br/>
                  <span className="auction-bidding__label-addendum">Current: {currentBidAmount ? `$` + formatPrice(currentBidAmount) : '—'} </span>
                </label>
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
                <label className="label" htmlFor="bid">Minimum Bid<br/>
                  <span className="auction-bidding__label-addendum">Current: {minimumBidAmount ? `$` + formatPrice(minimumBidAmount) : '—'} </span>
                </label>
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
        {/* BEGIN SUBMIT BARGING SECTION */}
        <div className="qa-submit-barges-panel">
          <CollapsibleSection
            trigger="Submit Barges"
            classParentString="collapsing-auction-barging"
            open={false}
          >
            <form className="auction-barging__container">
              { barges.map((barge) =>
                <div className="qa-barge-header" key={barge.id}>
                  <CollapsibleSection
                    trigger={ `${barge.name} (${barge.imo_number})` }
                    classParentString="auction-barging__barge"
                    open={false}
                  >
                    <div className="auction-barging__barge__header">
                      <div className="auction-barging__barge__content">
                        <p><strong>Port</strong> {barge.port}</p>
                        <p><strong>Approved for</strong> (Approved for)</p>
                        <p><strong>Last SIRE Inspection</strong> ({barge.sire_inspection_date})</p>
                      </div>
                    </div>
                  </CollapsibleSection>
                </div>
              )}
            </form>
          </CollapsibleSection>
        </div>
        {/* END SUBMIT BARGING SECTION */}
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
                  <label className="label" htmlFor="bid">Bid Amount
                    <span className="auction-bidding__label-addendum">Current:  {currentBidAmount ? `$` + formatPrice(currentBidAmount) : '—'} </span></label>
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
                  <label className="label" htmlFor="bid">Minimum Bid
                    <span className="auction-bidding__label-addendum">Current: {minimumBidAmount ? `$` + formatPrice(minimumBidAmount) : '—'}</span></label>
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
        </CollapsibleSection>
        {/* BEGIN SUBMIT BARGING SECTION */}
        <CollapsibleSection
          trigger="Submit Barges"
          classParentString="collapsing-auction-barging"
          open={false}
        >
          <form className="auction-barging__container">
            { barges.map((barge) =>
              <CollapsibleSection
                key={barge.id}
                trigger={ `${barge.name} (${barge.imo_number})` }
                classParentString="auction-barging__barge"
                open={false}
                className="qa-barge-header"
              >
                <div className="auction-barging__barge__header">
                  <div className="auction-barging__barge__content">
                    <p><strong>Port</strong> {barge.port}</p>
                    <p><strong>Approved for</strong> (Approved for)</p>
                    <p><strong>Last SIRE Inspection</strong> ({barge.sire_inspection_date})</p>
                  </div>
                </div>
              </CollapsibleSection>
            )}
          </form>
        </CollapsibleSection>
        {/* END SUBMIT BARGING SECTION */}
      </MediaQuery>
    </div>
  );
};

export default BiddingForm;
