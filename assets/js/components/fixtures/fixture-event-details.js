import React, { Fragment } from 'react';
import _ from 'lodash';
import FixtureEventChanges from './fixture-event-changes';


const FixtureEventDetails = ({ fixture, eventType, event }) => {
  let changes = eventType === 'Fixture changes proposed' || eventType === "Fixture updated" ? _.get(event, 'changes', {}) : {};
  const comment = _.get(changes, 'comment', null);
  changes = _.has(changes, 'comment') ? _
    .chain(changes)
    .omit('comment')
    .toPairs()
    .value() : _
    .chain(changes)
    .toPairs()
    .value();

  const previousValues = _
    .chain(changes)
    .map(([key, _value]) => {
      switch (key) {
        case "fuel":
        case "supplier":
        case "vessel":
          return [key, _.get(event.fixture, `${key}.name`)]
        default:
          return [key, _.get(event.fixture, key)]
      }
    })
    .value();

  if (eventType === "Fixture changes proposed") {
    const user = _.get(event, 'user');
    return (
      <Fragment>
        <div className="has-margin-bottom-sm">
          <span><b>Previous Values</b></span>
          <FixtureEventChanges eventType={eventType} changes={previousValues} />
        </div>
        <div>
          <span><b>Proposed Changes</b></span>
          <FixtureEventChanges eventType={eventType} changes={changes} comment={comment} />
        </div>
        <div className='has-margin-top-sm'>
          <span><b>{user.company.name}</b> </span>
          <span>{user.first_name} {user.last_name}</span>
        </div>
      </Fragment>
    )
  } else if (eventType === "Fixture updated") {
      return (
        <Fragment>
          <div className="has-margin-bottom-sm">
            <span><b>Previous Values</b></span>
            <FixtureEventChanges eventType={eventType} changes={previousValues} />
          </div>
          <div>
            <span><b>Changes</b></span>
            <FixtureEventChanges eventType={eventType} changes={changes} comment={comment} />
          </div>
        </Fragment>
      )
  } else if (eventType === "Fixture created") {
    let originalValues = {
      'fuel': _.get(fixture, 'original_fuel.name'),
      'vessel': _.get(fixture, 'original_vessel.name'),
      'supplier': _.get(fixture, 'original_supplier.name'),
      'quantity': _.get(fixture, 'original_quantity'),
      'price': _.get(fixture, 'original_price'),
      'eta': _.get(fixture, 'original_eta'),
      'etd': _.get(fixture, 'original_etd')
    }
    originalValues = _.toPairs(originalValues)
    return (
      <Fragment>
        <span><b>Original Values</b></span>
        <FixtureEventChanges eventType={eventType} changes={originalValues} />
      </Fragment>
    )
  } else if (eventType === "Fixture delivered") {
    let deliveredValues = {
      'fuel': _.get(fixture, 'delivered_fuel.name'),
      'vessel': _.get(fixture, 'delivered_vessel.name'),
      'supplier': _.get(fixture, 'delivered_supplier.name'),
      'quantity': _.get(fixture, 'delivered_quantity'),
      'price': _.get(fixture, 'delivered_price'),
      'eta': _.get(fixture, 'delivered_eta'),
      'etd': _.get(fixture, 'delivered_etd')
    }
    deliveredValues = _.toPairs(deliveredValues)
    return (
      <Fragment>
        <span><b>Delivered Values</b></span>
        <FixtureEventChanges eventType={eventType} changes={deliveredValues} />
      </Fragment>
    )
  } else {
    return null;
  }
}

export default FixtureEventDetails;
