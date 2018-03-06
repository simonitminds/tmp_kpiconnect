import _ from 'lodash';
import React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import AuctionShow from '../components/auction/show';
import { getAllAuctions, subscribeToAuctionUpdates, submitBid } from '../actions';

const mapStateToProps = (state) => {
  const auction = _.chain(state.auctionsReducer.auctions)
    .filter(['id', window.auctionId])
    .first()
    .value();
  return {
    auction,
    loading: state.auctionsReducer.loading
  }
};

const mapDispatchToProps = (dispatch) => ({
  dispatch,
  formSubmit(auction_id, ev) {
    ev.preventDefault();

    dispatch(submitBid(auction_id, new FormData(ev.target)))
  },
  ...bindActionCreators(dispatch)
});

export class AuctionContainer extends React.Component {

  dispatchItem() {
    this.props.dispatch(getAllAuctions());
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
