import React from 'react';
import _ from 'lodash';
import { formatTime, formatPrice } from '../../utilities';
import SolutionComment from './solution-comment';
import InputField from '../input-field';

export default class BuyerBestSolution extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      solutionCommentBidId: null
    }
  }
  setSolutionCommentBidId(bidId) {
    this.setState({solutionCommentBidId: bidId});
  }

  render() {
    const auctionPayload = this.props.auctionPayload;
    const auctionStatus = _.get(auctionPayload, 'status');
    const acceptBid = this.props.acceptBid;
    const lowestBid = _.get(auctionPayload, 'lowest_bids[0]');
    const lowestBidId = _.get(lowestBid, 'id');
    const winningBidId = _.get(auctionPayload, 'winning_bid.id');
    const remainingBids = _.chain(auctionPayload)
      .get('bid_history', [])
      .reject(['id', lowestBidId])
      .reject(['id', winningBidId])
      .orderBy(['amount', 'time_entered'],['asc', 'asc'])
      .value();


    const bidAcceptDisplay = (bid) => {
      if(auctionStatus == 'closed'){
        return "";
      } else if(this.state.solutionCommentBidId == bid.id) {
        return (
          <form className="box box--nested-base box--nested-base--extra-nested box--best-solution-comment is-gray-1 has-padding-top-md" onSubmit={acceptBid.bind(this, auctionPayload.auction.id, bid.id)}>
            {lowestBidId != bid.id ?
            "" :
            <span className="is-inline-block has-margin-bottom-lg"><strong>Are you sure that you want to accept this offer?</strong></span>
            }

            <SolutionComment showInput={lowestBidId != bid.id} bid={bid} auctionStatus={auctionStatus} />

            <div className="has-margin-top-md has-margin-bottom-sm"><i>Optional: Specify the Port Agent handling delivery</i></div>
            <InputField
              model={'auction'}
              field={'port_agent'}
              labelText={'Port Agent'}
              value={auctionPayload.auction.port_agent}
              expandedInput={true}
              opts={{ labelClass: 'label is-capitalized has-text-left has-margin-bottom-xs' }}
            />
            <div className="field is-expanded is-grouped is-grouped-right">
              <div className="control">
                <button className="button is-gray-3" onClick={this.setSolutionCommentBidId.bind(this, null)}>
                  Cancel
                </button>
              </div>
              <div className="control">
                  <button
                    disabled={auctionPayload.status != 'decision'}
                    className={`button is-success qa-accept-bid`}
                    type="submit"
                  >
                    Accept Offer
                  </button>
              </div>
            </div>
          </form>
        );
      } else {
        return("");
      }
    }

    const bidDisplay = (bid) => {
      return (
        <div>
          <div className="auction-solution__header">
            <h3 className="auction-solution__title is-inline-block">{bid.supplier}</h3>
            <div className="auction-solution__content">
              <span className="has-text-weight-bold has-padding-right-xs">${formatPrice(bid.amount)}</span> ({formatTime(bid.time_entered)})
              <button
                className={`button is-small has-margin-left-md qa-select-bid-${bid.id} ${auctionPayload.status != 'decision' ? 'is-hidden' : ''}`}
                onClick={
                  this.state.solutionCommentBidId == bid.id ? this.setSolutionCommentBidId.bind(this, null)
                                                            : this.setSolutionCommentBidId.bind(this, bid.id)
                }
              >
                Select
              </button>
            </div>
          </div>
          { bidAcceptDisplay(bid) }
        </div>
      );
    }

    const bestSolutionDisplay = () => {
      if (lowestBid) {
        return (
          <div className={`box auction-solution auction-solution--best qa-best-solution-${lowestBidId}`}>
            {bidDisplay(lowestBid)}
          </div>
        );
      } else {
        return (
          <div className="auction-table-placeholder">
            <i>No bids had been placed on this auction</i>
          </div>
        );
      }
    }

    const otherSolutionDisplay = () => {
      if (remainingBids.length > 0) {
        return (
          <div className="box box--margin-bottom">
            <div className="box__subsection has-padding-bottom-none">
              <h3 className="box__header box__header--bordered has-margin-bottom-md">Other Solutions</h3>
            </div>
            {_.map(remainingBids, (bid) => {
              return (
                <div key={bid.id} className={`box auction-solution qa-other-solution-${bid.id}`}>
                  {bidDisplay(bid)}
                </div>
              );
            })}
          </div>
        );
      }
    }

    return(
      <div className="auction-solution__container">
        <div className="box">
          <div className="box__subsection has-padding-bottom-none">
            <h3 className="box__header box__header--bordered has-margin-bottom-md">Best Solution</h3>
            { bestSolutionDisplay() }
          </div>
        </div>
        { otherSolutionDisplay() }
      </div>
    );
  }
};
