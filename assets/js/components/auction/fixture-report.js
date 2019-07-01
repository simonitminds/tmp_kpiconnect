import React, { Component } from 'react';
import _ from 'lodash';
import FixtureEvent from '../fixtures/fixture-event';
import { formatUTCDateTime } from '../../utilities';

const FixtureReport = ({ fixtureEventPayload }) => {
  console.log(fixtureEventPayload)
  const fixture = _.get(fixtureEventPayload, 'fixture');
  const auction = _.get(fixtureEventPayload, 'auction');
  const events = _.get(fixtureEventPayload, 'events');
  console.log(events.length)
  console.log(auction)

  return(
    <>
      {
        _.map(events, event => {
          return(
            <div key={event.id}>
              <div>{formatUTCDateTime(event.time_entered)}</div>

              <div>
                <span className="has-text-weight-bold has-padding-right-xs">
                  {event.type}
                </span>
              </div>
            </div>
          )
        })
      }
    </>
  )
}

export default FixtureReport;
