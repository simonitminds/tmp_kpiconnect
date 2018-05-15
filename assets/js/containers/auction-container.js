import _ from 'lodash';
import React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import AuctionShow from '../components/auction/show';
import {
  getAllAuctionPayloads,
  acceptWinningBid,
  setPortAgent,
  subscribeToAuctionUpdates,
  submitBid,
  updateBidStatus
} from '../actions';

const mapStateToProps = (state) => {
  const auctionPayload = _.chain(state.auctionsReducer.auctionPayloads)
    .filter(['auction.id', window.auctionId])
    .first()
    .value();
  return {
    auctionPayload,
    connection: state.auctionsReducer.connection,
    loading: state.auctionsReducer.loading
  }
};

const mapDispatchToProps = (dispatch) => ({
  dispatch,
  formSubmit(auctionId, ev) {
    ev.preventDefault();

    const elements = ev.target.elements;
    const bidData = {
      'bid': {
        'amount': elements.amount.value
      }
    };

    dispatch(submitBid(auctionId, bidData));
  },
  acceptBid(auctionId, bidId, ev) {
    ev.preventDefault();

    const elements = ev.target.elements;
    let bidComment = {'comment': ''};
    if(elements.comment) {
      bidComment = {
        'comment': elements.comment.value
      };
    }
    const portAgent = {'port_agent': elements.auction_port_agent.value};

    dispatch(setPortAgent(auctionId, portAgent));
    dispatch(acceptWinningBid(auctionId, bidId, bidComment));
  },
  ...bindActionCreators({ updateBidStatus }, dispatch)
});

export class AuctionContainer extends React.Component {

  dispatchItem() {
    this.props.dispatch(subscribeToAuctionUpdates());
  }
  componentDidMount() {
    this.dispatchItem();
  }
  componentDidUpdate(prevProps) {
    if (this.props.id !== prevProps.id) {
      this.dispatchItem();
    }
  }


  render() {
    if (this.props.loading) {
      return <div className="alert is-info">Loading...</div>
    } else {
      return <AuctionShow {...this.props}/>;
    }
  }
}

export default connect(mapStateToProps, mapDispatchToProps)(AuctionContainer);
