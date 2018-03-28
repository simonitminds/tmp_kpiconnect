import _ from 'lodash';
import React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import AuctionShow from '../components/auction/show';
import { getAllAuctionPayloads, subscribeToAuctionUpdates, submitBid, selectBid } from '../actions';

const mapStateToProps = (state) => {
  const auctionPayload = _.chain(state.auctionsReducer.auctionPayloads)
    .filter(['auction.id', window.auctionId])
    .first()
    .value();
  return {
    auctionPayload,
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

    dispatch(submitBid(auctionId, bidData))
  },
  ...bindActionCreators({ selectBid }, dispatch)
});

export class AuctionContainer extends React.Component {

  dispatchItem() {
    this.props.dispatch(getAllAuctionPayloads());
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
      return <div>Loading...</div>
    } else {
      return <AuctionShow {...this.props}/>;
    }
  }
}

export default connect(mapStateToProps, mapDispatchToProps)(AuctionContainer);
