import React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import AuctionsIndex from '../components/auction/index'
import { getAllAuctions} from '../actions';

const mapStateToProps = (state) => {
  return {
    auctions: state.auctionsReducer.auctions
  }
};

const mapDispatchToProps = (dispatch) => ({
  dispatch,
  ...bindActionCreators(dispatch)
});

export class AuctionsContainer extends React.Component {
  dispatchItem() {
    this.props.dispatch(getAllAuctions());
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
    return <AuctionsIndex {...this.props} />;
  }
}

export default connect(mapStateToProps, mapDispatchToProps)(AuctionsContainer);
