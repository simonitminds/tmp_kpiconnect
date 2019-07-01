import React, { Fragment } from 'react';
import { formatUTCDateTime } from '../../utilities';

const FixtureEvent = ({ fixture, auction, event }) => {
  console.log(event.type)
  console.log(event)
  return(
    <Fragment>
      <div>{formatUTCDateTime(event.time_entered)}</div>

      <div>
        <span className="has-text-weight-bold has-padding-right-xs">
          {event.type}
        </span>
      </div>
    </Fragment>
  )
}

export default FixtureEvent;
