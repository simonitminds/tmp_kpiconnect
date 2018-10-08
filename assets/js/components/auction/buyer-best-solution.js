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
    const onSelectSolution = (bidIds) => { this.setState({bidIds: bidIds}) }


   //TODO: Move out Other Solution Display
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
            <SolutionDisplay auctionPayload={auctionPayload} solution={bestSolution} title={"Best Solution"} acceptBid={acceptBid} best={true} />
            <SolutionDisplay auctionPayload={auctionPayload} solution={bestSingleSupplier} title={"Best Solution"} acceptBid={acceptBid} />
          </div>
        </div>
      </div>
    );
  }
};
