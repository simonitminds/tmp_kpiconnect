import _ from 'lodash';
import React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import AuctionShow from '../components/auction/show';
import { getAllAuctions, subscribeToAuctionUpdates } from '../actions';

const mapStateToProps = (state) => {
  return {
    auctions: state.auctionsReducer.auctions,
    loading: state.auctionsReducer.loading
  }
};

const mapDispatchToProps = (dispatch) => ({
  dispatch,
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
    const auction = _.chain(this.props.auctions)
      .filter(['id', window.auctionId])
      .first()
      .value();

    if (this.props.loading) {
      return <div>Loading...</div>
    } else {
      return <AuctionShow auction={auction} />;
    }
  }
}

export default connect(mapStateToProps, mapDispatchToProps)(AuctionContainer);
