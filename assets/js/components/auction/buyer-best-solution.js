import React from 'react';
import _ from 'lodash';
import { formatTime, formatPrice } from '../../utilities';
import SolutionComment from './solution-comment';
import SolutionDisplay from './solution-display';
import InputField from '../input-field';

export default class BuyerBestSolution extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      solutionCommentBidId: null
    }
  }
  setSolutionCommentBidId(bidIds, isBest) {
    this.setState({
      solutionCommentBidId: bidIds,
      bestSolutionSelected: isBest
    });
  }

  render() {
    const auctionPayload = this.props.auctionPayload;
    const auctionStatus = _.get(auctionPayload, 'status');
    const acceptBid = this.props.acceptBid;
    const lowestBid = _.get(auctionPayload, 'lowest_bids[0]');
    const lowestBidId = _.get(lowestBid, 'id');
    const winningBidId = _.get(auctionPayload, 'winning_bid.id');
    const is_traded_bid = _.get(auctionPayload, 'lowest_bids.is_traded_bid');
    const remainingBids = _.chain(auctionPayload)
      .get('bid_history', [])
      .reject(['id', lowestBidId])
      .reject(['id', winningBidId])
      .orderBy(['amount', 'time_entered'],['asc', 'asc'])
      .value();
    const bestSolution = _.get(auctionPayload, 'solutions.best_overall');
    const bestSingleSupplier = _.get(auctionPayload, 'solutions.best_single_supplier');
    const setCommentForSolution = (bidIds) => { this.state.solutionCommentBidId == bidIds ? this.setSolutionCommentBidId.bind(this, null) : this.setSolutionCommentBidId.bind(this, bidIds)}

     const bidAcceptDisplay = (bidIds) => {
      if(auctionStatus == 'closed'){
        return "";
      } else {
        return (
          <form className="auction-solution__confirmation box box--nested-base box--nested-base--extra-nested box--best-solution-comment is-gray-1 has-padding-top-md" onSubmit={acceptBid.bind(this, auctionPayload.auction.id, bidIds)}>
            { this.state.bestSolutionSelected ?
            "" :
            <span className="is-inline-block has-margin-bottom-lg"><strong>Are you sure that you want to accept this offer?</strong></span>
            }

            <SolutionComment showInput={!this.state.bestSolutionSelected} auctionStatus={auctionStatus} />

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
                  {bidDisplay(this.state.solutionCommentBidId)}
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
            <SolutionDisplay auctionPayload={auctionPayload} solution={bestSolution} title={"Best Solution"} acceptBid={acceptBid} best={true} onSelectSolution={setCommentForSolution.bind(this)} >
              { bidAcceptDisplay(this.state.solutionCommentBidId) }
            </SolutionDisplay>
            <SolutionDisplay auctionPayload={auctionPayload} solution={bestSingleSupplier} title={"Best Solution"} acceptBid={acceptBid} onSelectSolution={setCommentForSolution.bind(this)}>
              { bidAcceptDisplay(this.state.solutionCommentBidId) }
            </SolutionDisplay>
          </div>
        </div>
      </div>
    );
  }
};
