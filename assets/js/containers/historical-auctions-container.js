import React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import HistoricalAuctionsIndex from '../components/auction/historical-index'
import { subscribeToAuctionUpdates, getAllFinalizedAuctionPayloads, updateDate } from '../actions';

const mapStateToProps = (state) => {
  return {
    auctionPayloads: state.historicalAuctionsReducer.auctionPayloads,
    connection: state.historicalAuctionsReducer.connection,
    loading: state.historicalAuctionsReducer.loading
  }
};

const mapDispatchToProps = (dispatch) => ({
  dispatch,
  ...bindActionCreators({ updateDate }, dispatch)
});

export class HistoricalAuctionsContainer extends React.Component {
  dispatchItem() {
    this.props.dispatch(subscribeToAuctionUpdates(getAllFinalizedAuctionPayloads));
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
      return <HistoricalAuctionsIndex {...this.props} />
    }
  }
}

export default connect(mapStateToProps, mapDispatchToProps)(HistoricalAuctionsContainer);

