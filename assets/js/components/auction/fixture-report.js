import React, { Component, Fragment } from 'react';
import _ from 'lodash';
import FixtureEvent from '../fixtures/fixture-event';
import FixtureEventChanges from '../fixtures/fixture-event-changes';
import { formatUTCDateTime } from '../../utilities';
import { exportCSV, parseCSVFromEvents } from '../../reporting-utilities';

export default class FixtureReport extends Component {
  constructor(props) {
    super(props);
  }

  handleExportClick(_ev) {
    const fixtureEventPayload = this.props.fixtureEventPayload;
    const fixture = _.get(fixtureEventPayload, 'fixture');
    const auction = _.get(fixtureEventPayload, 'auction');
    const events = _.get(fixtureEventPayload, 'events');

    const csv = parseCSVFromEvents(fixture, auction, events);
    exportCSV(csv, 'fixture_events_report.csv');
  }

  render () {
    const fixtureEventPayload = this.props.fixtureEventPayload;
    const fixture = _.get(fixtureEventPayload, 'fixture');
    const auction = _.get(fixtureEventPayload, 'auction');
    const events = _.get(fixtureEventPayload, 'events');

    return(
      <Fragment>
        <div className="report__log">
          <div className="report__log__header">
            <div>
              <div>Time</div>
              <div>Event</div>
            </div>
          </div>
          <div className={`report__log__body qa-fixture-${fixture.id}-events`}>
            {
              _.map(events, event => {
                return(
                  <div key={event.id}>
                    <FixtureEvent fixture={fixture} event={event} />
                  </div>
                )
              })
            }
          </div>
        </div>
        <button className="auction_list__new-auction button is-link is-pulled-right is-small has-margin-bottom-md" onClick={this.handleExportClick.bind(this)}>
          <span>Export Fixture Report</span>
          <span className="icon"><i className="fas fa-file-export is-pulled-right"></i></span>
        </button>
      </Fragment>
    )
  }
}
