import React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import AuctionsIndex from '../components/auction/index'
import AuctionMessages from '../components/auction/auction-messages.js'
import { getAllAuctionPayloads, subscribeToAuctionUpdates, subscribeToAuctionMessages } from '../actions';

const mapStateToProps = (state) => {
  return {
    auctionPayloads: state.auctionsReducer.auctionPayloads,
    messagePayloads: state.messagesReducer.messagePayloads,
    connection: state.auctionsReducer.connection
  }
};

const mapDispatchToProps = (dispatch) => ({
  dispatch,
  ...bindActionCreators(dispatch)
});

export class AuctionsContainer extends React.Component {
  dispatchItem() {
    this.props.dispatch(subscribeToAuctionUpdates());
    this.props.dispatch(subscribeToAuctionMessages());
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
    return (
      <div>
        <AuctionsIndex {...this.props} />
        <AuctionMessages {...this.props}/>
      </div>
    );
  }
}

export default connect(mapStateToProps, mapDispatchToProps)(AuctionsContainer);
