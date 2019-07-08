import React, { Fragment } from 'react';
import _ from 'lodash';
import { formatUTCDateTime } from '../../utilities';
import FixtureEventDetails from './fixture-event-details';

const FixtureEvent = ({ fixture, event }) => {
  const type = _.get(event, 'type');
  const timeEntered = _.get(event, 'time_entered');

  return(
    <Fragment>
      <div>{formatUTCDateTime(timeEntered)}</div>

      <div>
        <div className="has-text-weight-bold has-padding-right-xs has-margin-bottom-sm">
          {type}
        </div>
        <FixtureEventDetails fixture={fixture} eventType={type} event={event} />
      </div>
    </Fragment>
  )
}

export default FixtureEvent;
