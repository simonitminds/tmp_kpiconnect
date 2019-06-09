import _ from 'lodash';
import React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import AdminAuctionFixturesIndex from '../components/auction/admin-fixture-index';
import { getAllFixturePayloads, deliverAuctionFixture } from '../actions';

const mapStateToProps = (state) => {
  return {
    fixturePayloads: state.fixturesReducer.fixturePayloads,
    connection: state.fixturesReducer.connection,
    loading: state.fixturesReducer.loading
  }
}

const mapDispatchToProps = (dispatch) => ({
  dispatch,
  deliverFixture(ev, fixtureId, auctionId) {
    const delivered = {'delivered': ev.target.checked};
    dispatch(deliverAuctionFixture(auctionId, fixtureId, delivered));
  },
  ...bindActionCreators(dispatch)
});

export class FixturesContainer extends React.Component {

  dispatchItem() {
    this.props.dispatch(getAllFixturePayloads());
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
      return <AdminAuctionFixturesIndex {...this.props} />
    }
  }
}

export default connect(mapStateToProps, mapDispatchToProps)(FixturesContainer);
