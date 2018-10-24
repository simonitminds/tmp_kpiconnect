import React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import AuctionsIndex from '../components/auction/index'
import AuctionMessaging from '../components/auction/auction-messaging.js'
import { getAllAuctionPayloads, subscribeToAuctionUpdates, subscribeToAuctionMessaging } from '../actions';

const mapStateToProps = (state) => {
  return {
    auctionPayloads: state.auctionsReducer.auctionPayloads,
    messagingPayloads: state.messagesReducer.messagingPayloads,
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
    this.props.dispatch(subscribeToAuctionMessaging());
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
        <AuctionMessaging {...this.props}/>
      </div>
    );
  }
}

export default connect(mapStateToProps, mapDispatchToProps)(AuctionsContainer);
