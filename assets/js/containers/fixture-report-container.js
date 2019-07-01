import React, { Component } from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import FixtureReport from '../components/auction/fixture-report';
import { getFixtureEventPayload } from '../actions';

const mapStateToProps = (state) => {
  return {
    fixtureEventPayload: state.fixtureReportReducer.fixtureEventPayload,
    connection: state.fixtureReportReducer.connection,
    loading: state.fixtureReportReducer.loading
  }
}

const mapDispatchToProps = (dispatch) => ({
  dispatch,
  ...bindActionCreators(dispatch)
});

export class FixtureReportContainer extends Component {
  constructor(props) {
    super(props);
  }

  dispatchItem() {
    this.props.dispatch(getFixtureEventPayload(this.props.fixture.id));
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
      return <FixtureReport {...this.props} />
    }
  }
}

export default connect(mapStateToProps, mapDispatchToProps)(FixtureReportContainer);
