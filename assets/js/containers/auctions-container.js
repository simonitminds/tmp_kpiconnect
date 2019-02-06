import React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import AuctionsIndex from '../components/auction/index'
import { subscribeToAuctionUpdates, getAllAuctionPayloads } from '../actions';

const mapStateToProps = (state) => {
  return {
    auctionPayloads: state.auctionsReducer.auctionPayloads,
    connection: state.auctionsReducer.connection,
    loading: state.auctionsReducer.loading
  }
};

const mapDispatchToProps = (dispatch) => ({
  dispatch,
  ...bindActionCreators(dispatch)
});

export class AuctionsContainer extends React.Component {
  dispatchItem() {
    this.props.dispatch(subscribeToAuctionUpdates(getAllAuctionPayloads));
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
      return <AuctionsIndex {...this.props} />
    }
  }
}

export default connect(mapStateToProps, mapDispatchToProps)(AuctionsContainer);
